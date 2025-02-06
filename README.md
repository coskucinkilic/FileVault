# FileVault

![FileVault](http://localhost:3000/examples/_attachments/filevault.png)

FileVault is a file storage application that allows you to upload files from your local computer and store them onchain. FileVault uses Internet Identity (II) for user login and authentication. Once files are uploaded, they can be downloaded at a later time, or they can be deleted.

This application's logic is written in [Motoko](https://internetcomputer.org/docs/current/motoko/main/getting-started/motoko-introduction), a programming language designed specifically for developing canisters on ICP.

### Project structure

The `/backend` folder contains the Motoko canister, `app.mo`. The `/frontend` folder contains web assets for the application's user interface. The user interface is written using the React framework. Edit the `mops.toml` file to add [Motoko dependencies](https://mops.one/) to the project.

## Continue building locally

To migrate your ICP Ninja project off of the web browser and develop it locally, follow these steps.

### 1. Download your project from ICP Ninja using the 'Download files' button.

### 2. Open the `BUILD.md` file for further instructions.
