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

#ifndef SIGNAL_ERROR_CODE_HPP_INCLUDED
#define SIGNAL_ERROR_CODE_HPP_INCLUDED

#include <signal.h>
#include <system_error>

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#ifdef __GNUC__
#include <excpt.h>
#else
#include <eh.h>
#endif
#endif

namespace sig {
namespace errors {

#ifdef _WIN32
#define SIG_ENUM(name, sig) name,
#else
#define SIG_ENUM(name, sig) name = sig,
#endif

	enum error_code_enum: int
	{
		SIG_ENUM(abort, SIGABRT)
		SIG_ENUM(alarm, SIGALRM)
		SIG_ENUM(arithmetic_exception, SIGFPE)
		SIG_ENUM(hangup, SIGHUP)
		SIG_ENUM(illegal, SIGILL)
		SIG_ENUM(interrupt, SIGINT)
		SIG_ENUM(kill, SIGKILL)
		SIG_ENUM(pipe, SIGPIPE)
		SIG_ENUM(quit, SIGQUIT)
		SIG_ENUM(segmentation, SIGSEGV)
		SIG_ENUM(terminate, SIGTERM)
		SIG_ENUM(user1, SIGUSR1)
		SIG_ENUM(user2, SIGUSR2)
		SIG_ENUM(child, SIGCHLD)
		SIG_ENUM(cont, SIGCONT)
		SIG_ENUM(stop, SIGSTOP)
		SIG_ENUM(terminal_stop, SIGTSTP)
		SIG_ENUM(terminal_in, SIGTTIN)
		SIG_ENUM(terminal_out, SIGTTOU)
		SIG_ENUM(bus, SIGBUS)
#ifdef SIGPOLL
		SIG_ENUM(poll, SIGPOLL)
#endif
		SIG_ENUM(profiler, SIGPROF)
		SIG_ENUM(system_call, SIGSYS)
		SIG_ENUM(trap, SIGTRAP)
		SIG_ENUM(urgent_data, SIGURG)
		SIG_ENUM(virtual_timer, SIGVTALRM)
		SIG_ENUM(cpu_limit, SIGXCPU)
		SIG_ENUM(file_size_limit, SIGXFSZ)
	};

#undef SIG_ENUM

	std::error_code make_error_code(error_code_enum e);
	std::error_condition make_error_condition(error_code_enum e);

} // namespace errors

std::error_category& sig_category();

#ifdef _WIN32
namespace seh_errors {

	// standard error codes are "int", the win32 exceptions are DWORD (i.e.
	// unsigned int). We coerce them into int here for compatibility, and we're
	// not concerned about their arithmetic
	enum error_code_enum: int
	{
		access_violation = int(EXCEPTION_ACCESS_VIOLATION),
		array_bounds_exceeded = int(EXCEPTION_ARRAY_BOUNDS_EXCEEDED),
		guard_page = int(EXCEPTION_GUARD_PAGE),
		stack_overflow = int(EXCEPTION_STACK_OVERFLOW),
		flt_stack_check = int(EXCEPTION_FLT_STACK_CHECK),
		in_page_error = int(EXCEPTION_IN_PAGE_ERROR),
		breakpoint = int(EXCEPTION_BREAKPOINT),
		single_step = int(EXCEPTION_SINGLE_STEP),
		datatype_misalignment = int(EXCEPTION_DATATYPE_MISALIGNMENT),
		flt_denormal_operand = int(EXCEPTION_FLT_DENORMAL_OPERAND),
		flt_divide_by_zero = int(EXCEPTION_FLT_DIVIDE_BY_ZERO),
		flt_inexact_result = int(EXCEPTION_FLT_INEXACT_RESULT),
		flt_invalid_operation = int(EXCEPTION_FLT_INVALID_OPERATION),
		flt_overflow = int(EXCEPTION_FLT_OVERFLOW),
		flt_underflow = int(EXCEPTION_FLT_UNDERFLOW),
		int_divide_by_zero = int(EXCEPTION_INT_DIVIDE_BY_ZERO),
		int_overflow = int(EXCEPTION_INT_OVERFLOW),
		illegal_instruction = int(EXCEPTION_ILLEGAL_INSTRUCTION),
		invalid_disposition = int(EXCEPTION_INVALID_DISPOSITION),
		priv_instruction = int(EXCEPTION_PRIV_INSTRUCTION),
		noncontinuable_exception = int(EXCEPTION_NONCONTINUABLE_EXCEPTION),
		status_unwind_consolidate = int(STATUS_UNWIND_CONSOLIDATE),
		invalid_handle = int(EXCEPTION_INVALID_HANDLE),
	};

	std::error_code make_error_code(error_code_enum e);
}

std::error_category& seh_category();

#endif // _WIN32

} // namespace sig

namespace std
{
template<>
struct is_error_code_enum<sig::errors::error_code_enum> : std::true_type {};

template<>
struct is_error_condition_enum<sig::errors::error_code_enum> : std::true_type {};

#ifdef _WIN32
template<>
struct is_error_code_enum<sig::seh_errors::error_code_enum> : std::true_type {};
#endif

} // namespace std

#endif

