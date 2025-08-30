@ECHO OFF
IF NOT ""=="%JAVA_HOME%" (
  SET "JAVA_EXE=%JAVA_HOME%\bin\java.exe"
) ELSE (
  SET "JAVA_EXE=java"
)
%JAVA_EXE% -version >NUL 2>&1 || (
  ECHO Java is required to run Gradle.
  EXIT /B 1
)
gradle %*
