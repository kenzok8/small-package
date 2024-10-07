/*

Copyright (c) 2017, Arvid Norberg
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

#ifndef TRY_SIGNAL_POSIX_HPP_INCLUDED
#define TRY_SIGNAL_POSIX_HPP_INCLUDED

#include "signal_error_code.hpp"
#include <setjmp.h> // for sigjmp_buf
#include <atomic>

namespace sig {

namespace detail {

extern std::atomic_flag once;

struct scoped_jmpbuf
{
	explicit scoped_jmpbuf(sigjmp_buf* ptr);
	~scoped_jmpbuf();
	scoped_jmpbuf(scoped_jmpbuf const&) = delete;
	scoped_jmpbuf& operator=(scoped_jmpbuf const&) = delete;
private:
	sigjmp_buf* _previous_ptr;
};

void handler(int const signo, siginfo_t* si, void*);
void setup_handler();

} // detail namespace

template <typename Fun>
void try_signal(Fun&& f)
{
	if (sig::detail::once.test_and_set() == false) {
		sig::detail::setup_handler();
	}

	sigjmp_buf buf;
	int const sig = sigsetjmp(buf, 1);
	// set the thread local jmpbuf pointer, and make sure it's cleared when we
	// leave the scope
	sig::detail::scoped_jmpbuf scope(&buf);
	if (sig != 0)
		throw std::system_error(static_cast<sig::errors::error_code_enum>(sig));

	f();
}

}

#endif

