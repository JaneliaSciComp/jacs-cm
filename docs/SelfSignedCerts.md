# Self-signed Certificates 

A self-signed certificate is generated during the `init-filesystem` step. This is not recommended for production use, and it requires some extra steps to get working.

In order to connect to https://HOST1, you need to accept the certificate in the browser. 

Then, in order to allow the Workstation to accept the cert, it needs to be added to Java's keystore as follows. You can either export it from the browser, or copy it over from the server (`$CONFIG_DIR/certs/cert.crt`).

## Mac

You need to know where the JVM is located. You can use the same method that the Workstation uses to locate the JVM, to ensure you get the same one. In a Terminal, type:
```
export JDK_HOME=`/usr/libexec/java_home -v 1.8`
```
Now, import the certificate. Here it's assumed the cert was saved to the desktop:
```
sudo keytool -import -v -trustcacerts -alias mouse1 -file ~/Desktop/cert.crt -keystore $JDK_HOME/jre/lib/security/cacerts -keypass changeit -storepass changeit
```

## Windows

On Windows, type "cmd" in Cortana to find the Command Prompt, then right-click it and select "Run as administrator". You need to find out where your JVM is installed by looking under C:\Program Files\Java. Then, import the certificate. Here it's assumed the cert was saved to the C: root directory:

```
C:\> "C:\Program Files\Java\jre1.8.0_181\bin\keytool.exe" -import -alias mouse1 -file C:\cert.crt -keystore "C:\Program Files\Java\jdk1.8.0_181\jre\lib\security\cacerts"  -keypass changeit -storepass changeit
```

