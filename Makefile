.PHONY: clean get-whl install-whl clean-whl build-mac-app pyinstaller build-dmg compile-mo needs-version

ifeq ($(OS),Windows_NT)
    OSNAME := WIN32
    PYTHON_EXEC := python
	PYTHON_EXEC_WITH_PATH := PYTHONPATH="./src;./kolibrisrc;%PYTHONPATH%" $(PYTHON_EXEC)
else
    OSNAME := $(shell uname -s)
    PYTHON_EXEC := python3
	PYTHON_EXEC_WITH_PATH := PYTHONPATH="./src:./kolibrisrc:$$PYTHONPATH" $(PYTHON_EXEC)
endif

NSSM_VERSION := 2.24

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

needs-version:
	$(eval KOLIBRI_VERSION ?= $(shell $(PYTHON_EXEC) -c "import os; import sys; sys.path = [os.path.abspath('kolibrisrc')] + sys.path; from pkginfo import Installed; print(Installed('kolibri').version)"))
	$(eval APP_VERSION ?= $(shell $(PYTHON_EXEC) read_version.py))

clean:
	rm -rf build dist

clean-whl:
	rm -rf whl
	mkdir whl

install-whl:
	rm -rf kolibrisrc
	pip3 install ${whl} -t kolibrisrc/
	# Read SQLAlchemy version from the unpacked whl file to avoid hard coding.
	# Manually install the sqlalchemy version
	@version=$$(grep -Eo '__version__ = "([0-9]+\.[0-9]+\.[0-9]+)"' kolibrisrc/kolibri/dist/sqlalchemy/__init__.py | grep -Eo "([0-9]+\.[0-9]+\.[0-9]+)"); \
	pip3 install sqlalchemy==$$version --no-binary :all:
	# Delete sqlalchemy from the dist folder
	rm -rf kolibrisrc/kolibri/dist/sqlalchemy
	rm -rf kolibrisrc/kolibri/dist/SQLAlchemy*
	# Cleanup the py2only folder
	rm -rf kolibrisrc/kolibri/dist/py2only
	# Delete cextensions folder
	rm -rf kolibrisrc/kolibri/dist/cext
	# This doesn't exist in 0.15, so don't error if it doesn't exist.
	echo "3.3.1" > kolibrisrc/kolibri/dist/importlib_resources/version.txt || true
	$(MAKE) loading-pages

loading-pages: needs-version
	# -X utf8 ensures Python uses UTF-8 for I/O, fixing UnicodeEncodeError on Windows.
ifeq ($(OS),Windows_NT)
	$(PYTHON_EXEC_WITH_PATH) -X utf8 -m kolibri manage loadingpage --output-dir src/kolibri_app/assets --version-text "${KOLIBRI_VERSION}-${APP_VERSION}"
else
	$(PYTHON_EXEC_WITH_PATH) -X utf8 -m kolibri manage loadingpage --output-dir src/kolibri_app/assets --version-text "${KOLIBRI_VERSION}-${APP_VERSION}"
endif

get-whl: clean-whl
	# Get the base filename from the URL, which might include a query string
	$(eval FILENAME_WITH_QUERY := $(shell basename "$(whl)"))
	# Strip the query string to get the final, clean filename
	$(eval CLEAN_FILENAME := $(shell echo "$(FILENAME_WITH_QUERY)" | sed 's/\?.*//'))
	# Define the final output path
	$(eval OUTPUT_PATH := whl/$(CLEAN_FILENAME))
	# Download the file directly to the correct, clean path
	wget -O "$(OUTPUT_PATH)" "$(whl)"
	# Call the install-whl target with the clean path
	$(MAKE) install-whl whl="$(OUTPUT_PATH)"

dependencies:
	PYINSTALLER_COMPILE_BOOTLOADER=1 pip3 install -r build_requires.txt --no-binary pyinstaller
	$(PYTHON_EXEC) -c "import PyInstaller; import os; os.truncate(os.path.join(PyInstaller.__path__[0], 'hooks', 'rthooks', 'pyi_rth_django.py'), 0)"

build-mac-app:
	$(eval LIBPYTHON_FOLDER = $(shell $(PYTHON_EXEC) -c 'from distutils.sysconfig import get_config_var; print(get_config_var("LIBDIR"))'))
	test -f ${LIBPYTHON_FOLDER}/libpython3.10.dylib || ln -s ${LIBPYTHON_FOLDER}/libpython3.10m.dylib ${LIBPYTHON_FOLDER}/libpython3.10.dylib
	$(MAKE) pyinstaller

ifeq ($(OS),Windows_NT)
pyinstaller: nssm
endif
pyinstaller: clean
	mkdir -p logs
	pip3 install .
	$(PYTHON_EXEC) -OO -m PyInstaller kolibri.spec

build-dmg: needs-version
	$(PYTHON_EXEC) -m dmgbuild -s build_config/dmgbuild_settings.py "Kolibri ${KOLIBRI_VERSION}" dist/kolibri-${KOLIBRI_VERSION}.dmg

.PHONY: webview2
# Download WebView2 runtime installer
webview2:
	@if [ ! -f installer/MicrosoftEdgeWebView2RuntimeInstallerX64.exe ]; then \
		echo "Downloading WebView2 full installer..."; \
		( \
			trap 'echo "Interrupted. Cleaning up..."; rm -f installer/MicrosoftEdgeWebView2RuntimeInstallerX64.exe; exit 1' INT TERM; \
			wget https://go.microsoft.com/fwlink/?linkid=2124701 -O installer/MicrosoftEdgeWebView2RuntimeInstallerX64.exe || { \
				echo "\Download failed. Cleaning up..."; \
				rm -f installer/MicrosoftEdgeWebView2RuntimeInstallerX64.exe; \
				exit 1; \
			} \
		); \
	else \
		echo "WebView2 full installer already present."; \
	fi

.PHONY: nssm
# Download NSSM for Windows service management
nssm:
	@if [ ! -f installer/nssm.exe ]; then \
		echo "Downloading NSSM..."; \
		( \
			trap 'echo "Interrupted. Cleaning up..."; rm -f installer/nssm.zip; rm -rf installer/nssm; exit 1' INT TERM; \
			mkdir -p installer/nssm && \
			wget https://nssm.cc/release/nssm-$(NSSM_VERSION).zip -O installer/nssm.zip || { \
				echo "Download failed. Cleaning up..."; \
				rm -f installer/nssm.zip; rm -rf installer/nssm; \
				exit 1; \
			}; \
			unzip -n installer/nssm.zip -d installer/nssm || { \
				echo "Unzip failed. Cleaning up..."; \
				rm -f installer/nssm.zip; rm -rf installer/nssm; \
				exit 1; \
			}; \
			cp installer/nssm/nssm-$(NSSM_VERSION)/win64/nssm.exe installer/ && \
			rm -rf installer/nssm installer/nssm.zip \
		); \
	else \
		echo "NSSM already present."; \
	fi

# Windows Installer Build
.PHONY: build-installer-windows
build-installer-windows: needs-version nssm webview2
ifeq ($(OS),Windows_NT)
	# Assumes Inno Setup is installed in the default location.
	# MSYS_NO_PATHCONV=1 prevents Git Bash/MINGW from converting the /D flag into a file path.
	MSYS_NO_PATHCONV=1 "C:\Program Files (x86)\Inno Setup 6\iscc.exe" /DAppVersion=$(KOLIBRI_VERSION) installer/kolibri.iss
else
	@echo "Windows installer can only be built on Windows."
endif

INNO_DEFAULT_ISL ?= C:/Program Files (x86)/Inno Setup 6/Default.isl
INNO_LANGUAGES_DIR ?= C:/Program Files (x86)/Inno Setup 6/Languages

.PHONY: new-language
new-language:
	$(MAKE) guard-LANG
	@echo "Creating new language scaffolding for '$(LANG)'..."
	$(PYTHON_EXEC) installer/translations/create_new_language.py \
		--name "$(LANG)" \
		--inno-languages-dir "$(INNO_LANGUAGES_DIR)"

.PHONY: update-translations
update-translations:
	@echo "Updating master language file from '$(INNO_DEFAULT_ISL)'..."
	$(PYTHON_EXEC) installer/translations/update_from_inno_default.py \
		--new-default "$(INNO_DEFAULT_ISL)" \
		--project-master "installer/translations/English.isl"
	@echo "Update complete. Please review update_report.txt and commit the changes to English.isl."

compile-mo:
	find src/kolibri_app/locales -name LC_MESSAGES -exec msgfmt {}/wxapp.po -o {}/wxapp.mo \;

.PHONY: codesign-mac-app
codesign-mac-app:
	$(MAKE) guard-MAC_CODESIGN_IDENTITY
# Mac App Code Signing
# CODESIGN should start with "Developer ID Application: ..."
	xattr -cr dist/Kolibri.app
	codesign \
		--sign "Developer ID Application: $(MAC_CODESIGN_IDENTITY)" \
		--verbose=3 \
		--deep \
		--timestamp \
		--force \
		--strict \
		--entitlements build_config/entitlements.plist \
		-o runtime \
		dist/Kolibri.app
	codesign --display --verbose=3 --entitlements :- dist/Kolibri.app
	codesign --verify --verbose=3 --deep --strict=all dist/Kolibri.app

.PHONY: codesign-dmg
codesign-dmg: needs-version
	$(MAKE) guard-MAC_CODESIGN_IDENTITY
	xattr -cr dist/kolibri-${KOLIBRI_VERSION}.dmg
	codesign \
		--sign "Developer ID Application: $(MAC_CODESIGN_IDENTITY)" \
		--verbose=3 \
		--deep \
		--timestamp \
		--force \
		--strict \
		--entitlements build_config/entitlements.plist \
		-o runtime \
		dist/kolibri-${KOLIBRI_VERSION}.dmg

.PHONY: notarize-dmg
notarize-dmg: needs-version
	$(MAKE) guard-MAC_NOTARIZE_USERNAME
	$(MAKE) guard-MAC_NOTARIZE_PASSWORD
	$(MAKE) guard-MAC_NOTARIZE_TEAM_ID
	./notarize-dmg.sh "./dist/kolibri-${KOLIBRI_VERSION}.dmg"


run-dev:
ifeq ($(OS),Windows_NT)
	$(PYTHON_EXEC_WITH_PATH) -m kolibri_app
else
	$(PYTHON_EXEC_WITH_PATH) -m kolibri_app
endif
