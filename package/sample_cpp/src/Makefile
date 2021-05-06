CFLAGS += 
LDFLAGS += 

TARGET = sample_cpp
OBJS = main.o

$(TARGET):  $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

%.o:%.c
	$(CXX) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o $(TARGET)
