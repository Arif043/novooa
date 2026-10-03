import json
import sys
import tempfile
import threading
import time
import unittest
import urllib.request
import uuid
from http.server import ThreadingHTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_script import execution
from novooa_script.multipart import MultipartError, parse_multipart
from novooa_script.server import ScriptHandler


def run(script, input="", variables=None, files=()):
    metadata = [{"displayName": name, "contentType": "application/octet-stream", "sizeBytes": len(data)} for name, data in files]
    request = {"script": script, "input": input, "variables": variables or {}, "files": metadata}
    return execution.execute(request, [data for _, data in files])


def multipart(parts):
    boundary = uuid.uuid4().hex
    body = b""
    for name, data in parts:
        body += f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n'.encode() + data + b"\r\n"
    body += f"--{boundary}--\r\n".encode()
    return f"multipart/form-data; boundary={boundary}", body


class MultipartTest(unittest.TestCase):
    def test_keeps_binary_files_byte_for_byte(self):
        data = b"\x00\xff\r\n--not-a-boundary\r\n\x89PNG\r\n\r\n"
        content_type, body = multipart([("request", b"{}"), ("file-0", data)])

        self.assertEqual(parse_multipart(content_type, body)["file-0"], data)

    def test_rejects_other_content_types(self):
        with self.assertRaises(MultipartError):
            parse_multipart("application/json", b"{}")


class ExecutionTest(unittest.TestCase):
    def test_returns_output_and_printed_text(self):
        result = run("print('hallo')\noutput = input.upper()", input="abc")

        self.assertEqual(result["output"], "ABC")
        self.assertEqual(result["printed"], "hallo\n")
        self.assertTrue(result["outputDefined"])

    def test_has_full_python_including_imports(self):
        result = run("import json, re, math\noutput = json.dumps({'n': math.floor(2.7)}) + str(bool(re.match('a', 'abc')))")

        self.assertEqual(result["output"], '{"n": 2}True')

    def test_hands_variables_to_the_next_script_and_skips_unserializable_ones(self):
        result = run("import json\ncount = count + 1\nhelper = lambda: 1", variables={"count": 1})

        self.assertEqual(result["variables"], {"count": 2})
        self.assertFalse(result["outputDefined"])

    def test_reads_attached_files_as_text_and_bytes(self):
        data = b"Zeile 1\nZeile 2\xff"
        script = (
            "names = [f['displayName'] for f in list_files()]\n"
            "raw = open(files[0]['path'], 'rb').read()\n"
            "output = f'{names}:{len(raw)}:{read_file('a.txt', encoding='latin-1')[:7]}'"
        )

        result = run(script, files=[("a.txt", data)])

        self.assertEqual(result["output"], f"['a.txt']:{len(data)}:Zeile 1")

    def test_reports_the_failing_line(self):
        with self.assertRaisesRegex(execution.ScriptFailed, r"Zeile 2: ZeroDivisionError"):
            run("x = 1\ny = x / 0")

    def test_reports_syntax_errors_with_line(self):
        with self.assertRaisesRegex(execution.ScriptFailed, r"Zeile 1: SyntaxError"):
            run("def (:")

    def test_output_must_be_a_string(self):
        with self.assertRaisesRegex(execution.ScriptFailed, "String-Variable output"):
            run("output = 5")

    def test_stops_scripts_that_run_too_long(self):
        original = execution.TIMEOUT_SECONDS
        execution.TIMEOUT_SECONDS = 1
        try:
            with self.assertRaisesRegex(execution.ScriptFailed, "abgebrochen"):
                run("while True:\n    pass")
        finally:
            execution.TIMEOUT_SECONDS = original

    def test_ends_processes_the_script_started(self):
        marker = f"novooa-test-{uuid.uuid4().hex}"
        run(f"import subprocess, sys\nsubprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)', '{marker}'])\noutput = 'x'")

        time.sleep(0.3)
        survivors = [p for p in Path("/proc").iterdir() if p.name.isdigit() and marker.encode() in (p / "cmdline").read_bytes()]
        self.assertEqual(survivors, [])

    def test_allows_many_threads_within_the_process_limit(self):
        result = run("import concurrent.futures as f\nwith f.ThreadPoolExecutor(max_workers=100) as ex:\n    total = sum(ex.map(lambda i: i, range(1000)))\noutput = str(total)")

        self.assertEqual(result["output"], "499500")

    def test_scripts_are_the_first_victims_when_memory_runs_out(self):
        result = run("output = open('/proc/self/oom_score_adj').read().strip()")

        self.assertEqual(result["output"], "1000")

    def test_forked_copies_do_not_corrupt_the_result(self):
        script = "import os\nfor _ in range(6):\n    os.fork()\noutput = 'fertig'"

        for _ in range(5):
            self.assertEqual(run(script)["output"], "fertig")

    def test_an_unreadable_result_is_a_script_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, "result.json").write_text("{kaputt")

            with self.assertRaisesRegex(execution.ScriptFailed, "ungültig"):
                execution.result_of(directory)

    def test_does_not_leave_run_directories_behind(self):
        before = set(Path(execution.WORK_ROOT).glob("run-*"))
        run("output = 'x'", files=[("a.txt", b"x")])

        self.assertEqual(set(Path(execution.WORK_ROOT).glob("run-*")), before)


class ServerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), ScriptHandler)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.url = f"http://127.0.0.1:{cls.server.server_address[1]}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()

    def post(self, parts):
        content_type, body = multipart(parts)
        request = urllib.request.Request(f"{self.url}/run", data=body, headers={"Content-Type": content_type})
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, json.load(response)
        except urllib.error.HTTPError as error:
            return error.code, json.load(error)

    def test_runs_a_script_with_a_binary_file(self):
        data = bytes(range(256)) * 4
        request = {"script": "output = str(len(open(files[0]['path'], 'rb').read()))", "input": "", "variables": {},
                   "files": [{"displayName": "b.bin", "contentType": "application/octet-stream", "sizeBytes": len(data)}]}

        status, body = self.post([("request", json.dumps(request).encode()), ("file-0", data)])

        self.assertEqual((status, body["output"]), (200, "1024"))

    def test_script_errors_are_422_with_a_readable_message(self):
        status, body = self.post([("request", json.dumps({"script": "raise ValueError('kaputt')"}).encode())])

        self.assertEqual(status, 422)
        self.assertIn("ValueError: kaputt", body["error"])

    def test_rejects_a_request_without_script_or_file_part(self):
        self.assertEqual(self.post([("request", b"{}")])[0], 400)
        missing = {"script": "output = ''", "files": [{"displayName": "a"}]}
        self.assertEqual(self.post([("request", json.dumps(missing).encode())])[0], 400)

    def test_health_check(self):
        with urllib.request.urlopen(f"{self.url}/healthz") as response:
            self.assertEqual(json.load(response), {"status": "ok"})


if __name__ == "__main__":
    unittest.main()
