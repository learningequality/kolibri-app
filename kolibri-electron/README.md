# kolibri-electron

This is the frontend for kolibri app. To launch this you'll need node.

1. Install dependencies with `yarn install`
2. Copy the kolibri backend folder generated with `kapew build`:

```
> cd ..
> python kapew.py build
> cp -r src/kolibri dist/win/Kolibri
> cp -r dist/win/Kolibri kolibri-electron/src/
> cd kolibri-electron
```
3. Then you can run the development version:

```
> yarn start
```

4. Or build the binary

```
> yarn make
```

The kolibri binary will be placed on
`kolibri-electron/out/kolibri-electron-win32-x64`
