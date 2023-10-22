# Carbon Black's Troubleshoot Log Collector 🛠️

Hello there! 👋 I've developed a nifty tool to help with troubleshooting common issues related to Carbon Black. Let's delve into the features! 😊

## Features 🌟

1. **Run as Admin Privileges** 🔑
2. **Firewall Rule Configuration Check** 🔥: Ensures that firewall rules are correctly set by trying to connect to essential domains.
3. **CB Certificate CRL Domain Connection Check** 🔒: Validates if CB can connect to the certificate CRL domain.
4. **GoDaddy Root Certificate Check** 🌐: Inspects if the GoDaddy root certificate is installed as expected.
5. **Hardware Requirement Verification** 💽: Checks for minimum requirements like available free memory and storage.
6. **Proxy Settings Examination** 🔄: Reviews the proxy settings for both CB and the system.
7. **Port Listening Check** 🚪: Ensures CB is able to listen on ports 443 or 5443 (the backup port for CB).
8. **Configuration File Copy** 📋
9. **CURL SSL Environment Variable Check** 🌀: Confirms if this variable is set by CB.
10. **Retrieval of `repcli` Status** 📊: Appends the status to the log file.
11. **CB System Services Status Check** 🚀: Checks if required CB System services are operational or if they've been halted for any reason.
12. **Error & Running Log Copy** 📜: Acquires copies of the CB Error and running logs.
13. **Diagnostic Log Collection with `repcli`** 🔍: Uses CB's own `repcli` to gather every diagnostic log.
14. **Pack Everything** 📦: Consolidates all the collected information into `output.zip`.

## Usage 🚀

*Open Terminal as Admin, Navigate to directory, Run cb_troubleshooter.bat*

## Feedback & Contributions ✨

Feel free to raise issues or provide feedback. Contributions are always welcome! 😇

---

Hope this tool proves beneficial in your troubleshooting journey with Carbon Black! Happy debugging! 😄
