FROM continuumio/miniconda3
MAINTAINER Daniel Himmelstein "daniel.himmelstein@gmail.com"

COPY spec-file.txt /
RUN conda create --yes --quiet --name thinklytics --file /spec-file.txt && \
  conda clean --yes --index-cache --lock --tarballs

ENV PATH /opt/conda/envs/thinklytics/bin:$PATH
