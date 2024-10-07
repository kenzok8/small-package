try_signal
==========

.. image:: https://travis-ci.org/arvidn/try_signal.svg?branch=master
    :target: https://travis-ci.org/arvidn/try_signal

.. image:: https://ci.appveyor.com/api/projects/status/le8jjroaai8081f1?svg=true
	:target: https://ci.appveyor.com/project/arvidn/try-signal/branch/master

The ``try_signal`` library provide a way to turn signals into C++ exceptions.
This is especially useful when performing disk I/O via memory mapped files,
where I/O errors are reported as ``SIGBUS`` and ``SIGSEGV`` or as structured
exceptions on windows.

The function ``try_signal`` takes a function object that will be executed once.
If the function causes a signal (or structured exception) to be raised, it will
throw a C++ exception. Note that RAII may not be relied upon within this function.
It may not rely on destructors being called. Stick to simple operations like
memcopy.

Example::

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

