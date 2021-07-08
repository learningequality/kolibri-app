const { app, BrowserWindow } = require('electron');
const path = require('path');
const child_process = require('child_process');
const http = require('http');
const { shell } = require('electron');

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (require('electron-squirrel-startup')) { // eslint-disable-line global-require
  app.quit();
}

const KOLIBRI = 'http://localhost:5000';
const pingTimeout = 20;
let loadRetries = 0;
let timeSpent = 0;
let maxRetries = 3;

let django = null;

const waitForKolibriUp = (mainWindow) => {
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
      mainWindow.loadFile(path.join(__dirname, 'Kolibri', 'assets', '_load.html'));
    }

    return;
  }

  http.get(`${KOLIBRI}/api/public/info`, (response) => {
    mainWindow.loadURL(KOLIBRI);
  }).on("error", (error) => {
    console.log("Error: " + error.message);
    setTimeout(() => { waitForKolibriUp(mainWindow); timeSpent++; }, 1000);
  });
};

const createWindow = () => {
  const mainWindow = new BrowserWindow({
    width: 1024,
    height: 768,
    autoHideMenuBar: true,
    center: true,
    icon: path.join(__dirname, 'icon.png'),
  });
  mainWindow.maximize();

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

  // Load the loading screen
  mainWindow.loadFile(path.join(__dirname, 'Kolibri', 'assets', '_load.html'));
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
  createWindow();
  runKolibri();
});

app.on('window-all-closed', () => {
  app.quit();
});
