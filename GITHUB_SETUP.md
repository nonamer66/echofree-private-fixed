# Private GitHub setup

1. Create a new **private** GitHub repository.
2. Extract this ZIP.
3. Open the extracted `EchoFree-private` folder.
4. Upload all files and folders from inside it to the repository root.
5. Be sure `.github/workflows/build-echofree.yml` exists in the repository.
6. Commit the upload to the `main` branch.
7. Open the repository's **Actions** tab.
8. Click **Build EchoFree ISO** in the left sidebar.
9. Click **Run workflow**.
10. When the run finishes, download `EchoFree-amd64-ISO` from the Artifacts section.

If the workflow does not appear:
- Confirm the repository contains `.github/workflows/build-echofree.yml`.
- Confirm GitHub Actions is enabled under Settings > Actions > General.
- Confirm the workflow file was committed to the default branch.
