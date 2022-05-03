FROM ubuntu:16.04

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y apt-utils \
software-properties-common

RUN add-apt-repository -y ppa:alex-p/tesseract-ocr

RUN apt-get install -y \
ghostscript \
libexempi3 \
pngquant \
python3-cffi \
python3-pip \
qpdf \
tesseract-ocr \
unpaper \
tesseract-ocr-deu \
tesseract-ocr-eng \
tesseract-ocr-pol \
tesseract-ocr-ces \
unpaper \
wget \
unoconv \
pdftk

RUN pip3 install ocrmypdf

RUN apt-get update && apt-get upgrade -y tesseract-ocr

ENV LANG=C.UTF-8
