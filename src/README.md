# Kira Frontend

Kira Frontend is a user interface for Kira Network Users to manage their accounts, balance, transfer tokens between different wallets.

## Installation

_NOTE: For development, run chrome browser without security enabled, unless the api doesn't fetch data due to the cors error._

#### - Frontend

- Install required packages in pubspec.yaml

```
flutter pub get
```

- Run commands

```
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true
flutter run -d web-server --dart-define=FLUTTER_WEB_USE_SKIA=true
```

- For development, you may need to run google chrome without cors

```
open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security
```

- Static Build

```
flutter build web
```

This command will generate static build of the web project in the `build/web` directory so that you can deploy it on hosting server.

_NOTE: To render svg in flutter, we need to enable SKIA mode when running command_

User input the password which will be used for encrypting mnemonic words and kira addresses, public/private keys.

After creating account, don't forget to keep the mnemonic words (seed) in a safe place and export the account as a file for restoring.

#### - Backend

To interact with INTERX, clone `KIP_9` branch of sekaid repository and check out INTERX readme for more information.

```
https://github.com/KiraCore/sekai/tree/KIP_9
```

- Run sekaid

```
sh sekaidtestsetup.sh
```

- Run INTERX

```
make install
interx
```

or

```
make start
```

#### - Environment File

Update `config.json` file for API configuration. It's in assets folder.

```
{
  "api_url": "http://<interx_url>:<interx_port>/api"
}
```
