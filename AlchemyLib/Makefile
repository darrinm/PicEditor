.SUFFIXES: .cpp .c .o .as .swf

NAME=as3_jpeg_wrapper
PATH:=${ALCHEMY_HOME}/achacks:${PATH}
GG = gluegen
INC = -I ${ALCHEMY_HOME}/jpeg
CC = gcc
CCPP = g++
CFLAGS = -fomit-frame-pointer -O3 -Wall
LDFLAGS = -L=${ALCHEMY_HOME}/jpeg -l=jpeg
SWC = $(NAME).swc
MXMLC = mxmlc
MXMLFLAGS = -library-path+=$(SWC) --target-player=10.0.0
OBJS = badatadst.o 

.cpp.o:
	$(CCPP) $(INC) $(CFLAGS) -c $<
.c.o:
	$(CC) $(INC) $(CFLAGS) -c $<
.as.swf: 
	$(MXMLC) $(MXMLFLAGS) $<

all: $(SWC) AlchemyLib.swf

glue.c : $(NAME).gg
	$(GG) $(NAME).gg -oas $(NAME).as -cpackage cmodule.$(NAME) -package hurlant.jpeg -class $(NAME)
	mkdir -p hurlant/jpeg
	mv $(NAME).as hurlant/jpeg/

glue.o : glue.c

$(SWC) : glue.o $(OBJS)
	$(CC) $(INC) $(CFLAGS) -swc -o $(SWC) glue.o $(OBJS) $(LDFLAGS)

clean:
	rm -f $(OBJS) glue.* $(NAME).as $(SWC)
	rm -f swfbridge.log
	rm -f *achacks*
	rm -f *.o *.swf
	rm -f -r _sb_* hurlant
