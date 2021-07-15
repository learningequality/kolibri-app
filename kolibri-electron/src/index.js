const { app, BrowserWindow } = require('electron');
const path = require('path');
const child_process = require('child_process');
const http = require('http');
const fs = require('fs');
const fsPromises = require('fs').promises;
const os = require('os');
const drivelist = require('drivelist');
const { shell } = require('electron');

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (require('electron-squirrel-startup')) { // eslint-disable-line global-require
  app.quit();
}

const NULL_PLUGIN_VERSION = '0';
const KOLIBRI = 'http://localhost:5000';
let pingTimeout = 20;
let mainWindow = null;
let loadRetries = 0;
let timeSpent = 0;
let maxRetries = 3;

let django = null;

async function getEndlessKeyDrive() {
  const drives = await drivelist.list();

  // Look for the endless key drive
  for (const d of drives.map((d) => d.mountpoints[0].path)) {
    console.log(`Looking for endless Key on ${d}`);
    const p = path.join(d, 'KOLIBRI_DATA');
    try {
      await fsPromises.access(p);
      return d;
    } catch (err) {
      console.log(`${p} doesn't exists, trying next`);
    }
  };

  return null;
}

async function getLoadingScreen() {
  const defaultLoading = path.join(__dirname, 'Kolibri', 'assets', '_load.html');

  // Try to use the custom loading screen from kolibri-explore-plugin
  const drive = await getEndlessKeyDrive();
  if (!drive) {
    return defaultLoading;
  }

  const loading = path.join(
    drive,
    'KOLIBRI_DATA',
    'extensions',
    'kolibri_explore_plugin',
    'loadingScreen',
    'index.html',
  );

  try {
    await fsPromises.access(loading);
    return loading;
  } catch (err) {
    console.log(`Loading screen not found ${loading}`);
  }

  return defaultLoading;
}

async function getPluginVersion() {
  const drive = await getEndlessKeyDrive();
  if (!drive) {
    console.error('Endless Key not found');
    return NULL_PLUGIN_VERSION;
  }
  const extensionsDir = path.join(drive, 'KOLIBRI_DATA', 'extensions');

  try {
    const files = await fsPromises.readdir(extensionsDir);
    for (const file of files) {
      // Looking for plugin kolibri_explore_plugin-VERSION.dist-info
      const re = /kolibri_explore_plugin-(\d+\.\d+\.\d+)\.dist-info/
      const match = file.match(re);
      if (match) {
        return match[1];
      }
    }
  } catch (err) {
    console.error(err);
  }

  return NULL_PLUGIN_VERSION;
}

// Checks for the ~/.endless-key/version file and compares with the Endless key
// kolibri-explore-plugin version. If the version is different, the
// ~/endless-key folder will be removed.
//
// Return true if the version file does not match the plugin version or if the
// .endless-key doesn't exists.
async function checkVersion() {
  console.log('Checking kolibri-app version file');
  const kolibriHome = path.join(os.homedir(), '.endless-key');
  const versionFile = path.join(kolibriHome, 'version');
  const pluginVersion = await getPluginVersion();
  let kolibriHomeVersion = NULL_PLUGIN_VERSION;

  try {
    kolibriHomeVersion = fs.readFileSync(versionFile, 'utf8').trim();
  } catch (error) {
    console.log('No version file found in .endless-key');
  }

  console.log(`${kolibriHomeVersion} < ${pluginVersion}`);
  if (kolibriHomeVersion < pluginVersion) {
    console.log('Newer version, replace the .endless-key directory and cleaning cache');
    await fsPromises.rm(kolibriHome, { recursive: true, force: true });
    mainWindow.webContents.session.clearCache();
    return true;
  }

  return false;
}

async function updateVersion() {
  const kolibriHome = path.join(os.homedir(), '.endless-key');
  const versionFile = path.join(kolibriHome, 'version');
  const pluginVersion = await getPluginVersion();

  await fsPromises.writeFile(versionFile, pluginVersion);
}

const waitForKolibriUp = () => {
  console.log('Kolibri server not yet started, checking again in one second...');

  if (timeSpent > pingTimeout) {
    const contents = mainWindow.webContents;

    if (loadRetries < maxRetries) {
      console.log('Kolibri server not starting, retrying...');
      contents.executeJavaScript('show_retry()', true);
      loadRetries++;
      timeSpent = 0;
      runKolibri();
      waitForKolibriUp(mainWindow);
    } else {
      contents.executeJavaScript('show_error()', true);
    }

    return;
  }

  http.get(`${KOLIBRI}/api/public/info`, (response) => {
    mainWindow.loadURL(KOLIBRI);
    updateVersion();
  }).on("error", (error) => {
    console.log("Error: " + error.message);
    setTimeout(() => { waitForKolibriUp(mainWindow); timeSpent++; }, 1000);
  });
};

async function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 768,
    autoHideMenuBar: true,
    center: true,
    icon: path.join(__dirname, 'icon.png'),
    show:false,
  });
  mainWindow.maximize();
  mainWindow.show();

  // Link handler to open external links on default browser
  const windowOpenHandler = ({url}) => {
    const absolute = /^https?:\/\//i;
    const isRelative = (u) => !absolute.test(url);
    if (url.startsWith('file:') || url.startsWith(KOLIBRI) || isRelative(url)) {
      return {action: 'allow'};
    }
    shell.openExternal(url);
    return {action: 'deny'};
  };
  mainWindow.webContents.setWindowOpenHandler(windowOpenHandler);
  await mainWindow.loadFile(await getLoadingScreen());

  const firstLaunch = await checkVersion();
  if (firstLaunch) {
    mainWindow.webContents.executeJavaScript('firstLaunch()', true);
    // Adding 20 seconds to the pingTimeout to wait for the kolibri-home copy
    pingTimeout += 20;
  }
  waitForKolibriUp(mainWindow);
};

const runKolibri = () => {
  console.log('Running kolibri backend');
  if (django) {
    console.log('Killing previous stalled server');
    django.kill('SIGTERM');
  }

  django = child_process.spawn(path.join(__dirname, 'Kolibri', 'Kolibri.exe'));
  django.stdout.on('data', (data) => {
    console.log(`Kolibri: ${data}`);
  });

  django.stderr.on('data', (data) => {
    console.error(`Kolibri: ${data}`);
  });

  django.on('close', (code) => {
    console.log(`child process exited with code ${code}`);
  });
};

app.on('ready', () => {
  createWindow()
    .then(() => {
      runKolibri();
    });
});

app.on('window-all-closed', () => {
  app.quit();
});
