This file contains instructions for local development. 


## Tests 

When running tests locally, make sure to run them with `--concurrency=1` (or `-j 1` for short) -- i.e.:

```
dart test -j 1
```

If you're using VS Code, this can be added to the `.vscode/settings.json`:

```json
{
    "dart.lineLength": 80,
    "dart.testAdditionalArgs": [
        "-j",
        "1",
    ],
}
```

