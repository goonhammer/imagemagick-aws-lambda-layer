FROM public.ecr.aws/sam/build-nodejs18.x:latest

WORKDIR /build

COPY Makefile ./

RUN yum update -y
RUN yum groupinstall -y "Development Tools"
RUN yum install -y cmake
RUN yum install -y fontconfig
RUN yum install -y freetype
RUN yum install -y ghostscript

RUN make all

WORKDIR /opt

# archive with symbolic links
RUN zip -ry /build/imagemagick-layer.zip .

RUN mkdir /dist && \
 echo "cp /build/imagemagick-layer.zip /dist/imagemagick-layer.zip" > /entrypoint.sh && \
 chmod +x /entrypoint.sh

ENTRYPOINT "/entrypoint.sh"
