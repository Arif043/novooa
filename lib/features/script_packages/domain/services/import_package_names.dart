/// Welches PyPI-Paket ein Import-Modul meist liefert. Wo Modul und Paket
/// gleich heißen, gilt der Modulname; die Tabelle kennt nur die Abweichungen.
/// Der Vorschlag lässt sich vor dem Installieren ändern.
class ImportPackageNames {
  const ImportPackageNames();

  String packageFor(String module) => _differing[module] ?? module;
}

const _differing = {
  'cv2': 'opencv-python-headless',
  'PIL': 'Pillow',
  'sklearn': 'scikit-learn',
  'skimage': 'scikit-image',
  'yaml': 'PyYAML',
  'bs4': 'beautifulsoup4',
  'dateutil': 'python-dateutil',
  'docx': 'python-docx',
  'pptx': 'python-pptx',
  'fitz': 'PyMuPDF',
  'dotenv': 'python-dotenv',
  'jwt': 'PyJWT',
  'Crypto': 'pycryptodome',
  'magic': 'python-magic',
  'serial': 'pyserial',
  'usb': 'pyusb',
  'attr': 'attrs',
  'google': 'protobuf',
  'OpenSSL': 'pyOpenSSL',
  'MySQLdb': 'mysqlclient',
  'psycopg2': 'psycopg2-binary',
  'Levenshtein': 'python-Levenshtein',
  'slugify': 'python-slugify',
  'multipart': 'python-multipart',
  'zmq': 'pyzmq',
  'win32api': 'pywin32',
};
