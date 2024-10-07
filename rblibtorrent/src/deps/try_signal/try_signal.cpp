/*

Copyright (c) 2016, Arvid Norberg
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

*/

#include <cassert>
#include <system_error>
#include <atomic>
#include <csetjmp>
#include <csignal>

#include "try_signal.hpp"

#if !defined _WIN32
// linux

namespace sig {
namespace detail {

namespace {
thread_local sigjmp_buf* jmpbuf = nullptr;
}

std::atomic_flag once = ATOMIC_FLAG_INIT;

scoped_jmpbuf::scoped_jmpbuf(sigjmp_buf* ptr)
{
	_previous_ptr = jmpbuf;
	jmpbuf = ptr;
	std::atomic_signal_fence(std::memory_order_release);
}

scoped_jmpbuf::~scoped_jmpbuf() { jmpbuf = _previous_ptr; }

void handler(int const signo, siginfo_t*, void*)
{
	std::atomic_signal_fence(std::memory_order_acquire);
	if (jmpbuf)
		siglongjmp(*jmpbuf, signo);

	// this signal was not caused within the scope of a try_signal object,
	// invoke the default handler
	signal(signo, SIG_DFL);
	raise(signo);
}

void setup_handler()
{
	struct sigaction sa;
	sa.sa_sigaction = &sig::detail::handler;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = SA_SIGINFO;
	sigaction(SIGSEGV, &sa, nullptr);
	sigaction(SIGBUS, &sa, nullptr);
}

} // detail namespace
} // sig namespace

#elif __GNUC__
// mingw

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

namespace sig {
namespace detail {

thread_local jmp_buf* jmpbuf = nullptr;

long CALLBACK handler(EXCEPTION_POINTERS* pointers)
{
	std::atomic_signal_fence(std::memory_order_acquire);
	if (jmpbuf)
		longjmp(*jmpbuf, pointers->ExceptionRecord->ExceptionCode);
	return EXCEPTION_CONTINUE_SEARCH;
}

scoped_handler::scoped_handler(jmp_buf* ptr)
{
	_previous_ptr = jmpbuf;
	jmpbuf = ptr;
	std::atomic_signal_fence(std::memory_order_release);
	_handle = AddVectoredExceptionHandler(1, sig::detail::handler);
}
scoped_handler::~scoped_handler()
{
	RemoveVectoredExceptionHandler(_handle);
	jmpbuf = _previous_ptr;
}

} // detail namespace
} // sig namespace

#else
// windows

#include <winnt.h> // for EXCEPTION_*

namespace sig {
namespace detail {

	// these are the kinds of SEH exceptions we'll translate into C++ exceptions
	bool catch_error(int const code)
	{
		return code == EXCEPTION_IN_PAGE_ERROR
			|| code == EXCEPTION_ACCESS_VIOLATION
			|| code == EXCEPTION_ARRAY_BOUNDS_EXCEEDED;
	}
} // detail namespace
} // namespace sig

#endif // _WIN32


