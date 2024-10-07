#include <stdexcept>
#include <array>
#include <cstring> // for memcpy

#include "try_signal.hpp"

int main()
{
	char const buf[] = "test...test";
	char dest[sizeof(buf)];

	{
		sig::try_signal([&]{
			std::memcpy(dest, buf, sizeof(buf));
		});
		if (!std::equal(buf, buf + sizeof(buf), dest)) {
			fprintf(stderr, "ERROR: buffer not copied correctly\n");
			return 1;
		}
	}

	try {
		void* invalid_pointer = nullptr;
		sig::try_signal([&]{
			std::memcpy(dest, buf, sizeof(buf));
			std::memcpy(dest, invalid_pointer, sizeof(buf));
		});
	}
	catch (std::system_error const& e)
	{
		if (e.code() != std::error_condition(sig::errors::segmentation)) {
			fprintf(stderr, "ERROR: expected segmentaiton violation error\n");
		}
		else {
			fprintf(stderr, "OK\n");
		}
		fprintf(stderr, "exited with expected system_error exception: %s\n", e.what());

		// we expect this to happen, so return 0
		return e.code() == std::error_condition(sig::errors::segmentation) ? 0 : 1;
	}

	// return non-zero here because we don't expect this
	fprintf(stderr, "ERROR: expected exit through exception\n");
	return 1;
}

