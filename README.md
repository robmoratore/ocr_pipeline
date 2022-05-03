# OCR Pipeline

## Environment preparation

### Docker container

#### Requirements

- [Download](https://www.docker.com/community-edition#/download) and install Docker if you don't have it setup on your machine.

#### Build the Docker Container

First, make sure the Docker engine is running on your machine. Then build the Docker container by calling the following command at the top-level of the repository:

```sh
docker build -t <image-name> .
```

Replace `<image-name>` with a name for the Docker image, e.g.
`preprocess`.

#### Run the Docker Container

Run the Docker container by calling the following command at the top-level of
the repository:

```sh
docker run -it --name <container-name> \
           -v <data-path>:/data \
           <image-name>:latest
```

Notes on argument values:

- `<container-name>` is used to identify the container (in case you want to
  interrupt and terminate it). This is optional and Docker will generate a
  random name if this is not set.

- `<data-path>` path to the directory where the data lives. This will be accessible by the container.

- `<image-name>` references the image name used when building the container.

#### Connecting and disconnecting to the container

The first time the container is ran, you will automatically be connected to the shell of the container. To exit the container, just exit you current terminal session or press 'Ctrl+d'.

To reconnect to the container, first check that it is running with:

```sh
docker ps
```

You should see you container with the `<container-name>` you specified. If it is not running then start it with:

```sh
docker start <container-name>
```

Then to enter the shell for the container:

```sh
docker exec -it <container-name> bash
```

You data will be located under `/data` in the container.

## Processing Workflow

The file processing will make changes to the original files. Therefore it is important that these steps are taken in a copy of the original data, in order to preserve the data as it was delivered by the customer.

### Make a copy of the files to be processed

```sh
cp -a /<source>/. /<destination>/
```
- `<source>` is the source directory to copy.

- `<destination>` is the destination where the files will be copied to.

- The `-a` option is an improved recursive option, that preserve all file attributes, and also preserve symlinks.

- The `.` at end of the source path is a specific cp syntax that allow to copy all files and folders, included hidden ones.

### Navigate to the new copied directory

All the processing steps to follow have to be run from the top most level of the directory of the newly created copy of the data.

```sh
cd <destination>
```

### Uncompress archives

If the data has archive files, these should first be uncompressed. The following command will uncompress the archives in the same directory as the original archive file to a directory with the name of the archive file.

```sh
find . -iname "*.<file-type>" | xargs -P 5 -I FILENAME sh -c 'unzip -o -d "$(dirname "FILENAME")" "FILENAME"; rm "FILENAME"'
```
- replace `<file-type>` with the type or archive you want to uncompress, e.g. `zip`.

### Normalise extensions

For consistency, we rename all file extensions to be lowercase

```sh
find . -type f -exec rename -f 's/\.([^.]+)$/.\L$1/' {} \;
```

### Convert files to PDF

In case there are any documents which include a mixture of text and images, which also need to be OCRed, we first convert them to pdf in order to process them in the following steps.

The package that is used can handle most file types which can be opened with LibreOffice.

In the command bellow, Excel, Word and PowerPoint files are converted to pdf.  

```sh
find . -type f \( -name '*.xls*' -o -name "*.doc*" -o -name "*.ppt*" \) -exec unoconv -f pdf {} \;
```

### OCR

To OCR, a library called ocrmypdf is used.

Documentation can be found [here](https://ocrmypdf.readthedocs.io/en/latest/installation.html#ubuntu-16-04-lts). There are many optional flags that can be used to improve results. It is highly recommended that these are explored.

The command will OCR the files in place, meaning that the original files will be replaced by an OCRed copy.

```sh
find . -printf '%p \n' -name '*.pdf' -type f -exec ocrmypdf '{}' '{}' -l eng+deu+ces+pol --redo-ocr --output-type pdf --max-image-mpixels 2560000000000000000 \;
```

Flags explanation:
- `-l` is used to specify the languages to be expected in the documents. This can greatly improve the quality of the OCR. If new languages need to be added, they first must be installed. More information can be found in the documentation.

- `--redo-ocr`: Text is categorised as either visible or invisible. Invisible text (OCR) is stripped out. Then an image of each page is created with visible text masked out. The page image is sent for OCR, and any additional text is inserted as OCR. If a file contains a mix of text and bitmap images that contain text, OCRmyPDF will locate the additional text in images without disrupting the existing text. This however significantly increases processing time. If time is of the essence, this flag can be omitted, or `--skip-text` can be used instead. More information can be found in the documentation.

- `--output-type pdf`: This sets the file output to pdf rather than the default pdf/a. While not strictly necessary, it prevents possible issues some pdf readers might have rendering pdf/a files.

- `--max-image-mpixels`: this package has a protection against malicious pdfs and won't open large ones by default. This means that pdfs with large diagrams might not open. Set a very large number of megapixels to ensure no documents will be ignored.

### Split PDFs into individual pages

A copy of the OCRed pdfs was created with one file per page.
To do this, first a copy of the directory structure must be created to the directory where the per page files will be saved.

To do this, first navigate to the top level directory of the data folder and run the following commands:

```sh
mkdir <destination>
cd <source>
find . -type d | cpio -pdvm <destination>
find . -type f -name '*.pdf' -exec sh -c 'pdftk "$0" burst output "../<destination>/$(dirname "${0#./}")/$(basename "$0" .pdf)_%04d.pdf"' {} \;
```
- `<source>` is the source directory to copy.

- `<destination>` is the destination where the files will be copied to.
