# Using Self-signed Certificates

A self-signed certificate is automatically generated during the `init-filesystem` step of a jacs-cm installation. For production use, it is recommended that you replace this certificate with a real one. The self-signed certificate is less secure, and it requires some extra steps to get working.

In order to connect to https://HOST1, you need to accept the certificate in the browser. This differs by browser.

Then, in order to allow the Workstation to accept the certificate, it needs to be added to Java's keystore. For this, you will need the certificate on the desktop computer where you are running the Workstation. You can either export it from the browser, or copy it over from the server. It is located in `$CONFIG_DIR/certs/cert.crt`.

## Mac

First, you need to know where the JVM is located. You can use the same method that the Workstation uses to locate the JVM. This ensures you are modifying the correct one. Open a Terminal and type:
```
export JDK_HOME=`/usr/libexec/java_home -v 1.8`
```
Now you can import the certificate into the keystore. Here it's assumed the cert was saved to the desktop:
```
sudo keytool -import -v -trustcacerts -alias mouse1 -file ~/Desktop/cert.crt -keystore $JDK_HOME/jre/lib/security/cacerts -keypass changeit -storepass changeit
```

## Windows

On Windows, type "cmd" in the Cortana box to find the Command Prompt, then right-click it and select "Run as administrator". You need to find out where your JVM is installed by looking under C:\Program Files\Java. Then, import the certificate. Here it's assumed the cert was saved to the C: root directory:

```
C:\> "C:\Program Files\Java\jre1.8.0_181\bin\keytool.exe" -import -alias mouse1 -file C:\cert.crt -keystore "C:\Program Files\Java\jdk1.8.0_181\jre\lib\security\cacerts"  -keypass changeit -storepass changeit
```

