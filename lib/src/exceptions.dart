abstract class MwebdServerException implements Exception {}

class MwebdServerAlreadyCreatedException implements MwebdServerException {}

class MwebdServerNotCreatedException implements MwebdServerException {}

class MwebdServerAlreadyRunningException implements MwebdServerException {}

class MwebdServerNotRunningException implements MwebdServerException {}

class MwebdServerDataDirDoesNotExistException implements MwebdServerException {}
