#include <stdexcept>
#include <vector>
#include <numeric>
#include "try_signal.hpp"
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

int main() try
{
	int fd = open("test_file", O_RDWR);
	void* map = mmap(nullptr, 1024, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

	std::vector<char> buf(1024);
	std::iota(buf.begin(), buf.end(), 0);

	// disk full or access after EOF are reported as exceptions
	sig::try_signal([&]{
		std::memcpy(map, buf.data(), buf.size());
	});

	munmap(map, 1024);
	close(fd);
	return 0;
}
catch (std::exception const& e)
{
	fprintf(stderr, "exited with exception: %s\n", e.what());
	return 1;
}

