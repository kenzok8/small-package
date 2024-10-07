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

#include <system_error>
#include <string>

#include "signal_error_code.hpp"

namespace {

	struct signal_error_category : std::error_category
	{
		const char* name() const noexcept override
		{ return "signal"; }
		std::string message(int ev) const noexcept override
		{
#define SIGNAL_CASE(x) case sig::errors::error_code_enum:: x: return #x;
			switch (ev)
			{
			SIGNAL_CASE(abort)
			SIGNAL_CASE(alarm)
			SIGNAL_CASE(arithmetic_exception)
			SIGNAL_CASE(hangup)
			SIGNAL_CASE(illegal)
			SIGNAL_CASE(interrupt)
			SIGNAL_CASE(kill)
			SIGNAL_CASE(pipe)
			SIGNAL_CASE(quit)
			case sig::errors::error_code_enum::segmentation: return "segmentation fault";
			SIGNAL_CASE(terminate)
			SIGNAL_CASE(user1)
			SIGNAL_CASE(user2)
			SIGNAL_CASE(child)
			SIGNAL_CASE(cont)
			SIGNAL_CASE(stop)
			SIGNAL_CASE(terminal_stop)
			SIGNAL_CASE(terminal_in)
			SIGNAL_CASE(terminal_out)
			SIGNAL_CASE(bus)
#ifdef SIGPOLL
			SIGNAL_CASE(poll)
#endif
			SIGNAL_CASE(profiler)
			SIGNAL_CASE(system_call)
			SIGNAL_CASE(trap)
			SIGNAL_CASE(urgent_data)
			SIGNAL_CASE(virtual_timer)
			SIGNAL_CASE(cpu_limit)
			SIGNAL_CASE(file_size_limit)
			default: return "unknown";
			}
#undef SIGNAL_CASE
		}
		std::error_condition default_error_condition(int ev) const noexcept override
		{ return {ev, *this}; }
	};
} // anonymous namespace

namespace sig {
namespace errors {

	std::error_code make_error_code(error_code_enum e)
	{
		return {e, sig_category()};
	}

	std::error_condition make_error_condition(error_code_enum e)
	{
		return {e, sig_category()};
	}

} // namespace errors

std::error_category& sig_category()
{
	static signal_error_category signal_category;
	return signal_category;
}

#ifdef _WIN32

namespace {
	sig::errors::error_code_enum map_exception_code(int const ev)
	{
		switch (ev)
		{
			case seh_errors::error_code_enum::access_violation:
			case seh_errors::error_code_enum::array_bounds_exceeded:
			case seh_errors::error_code_enum::guard_page:
			case seh_errors::error_code_enum::stack_overflow:
			case seh_errors::error_code_enum::flt_stack_check:
			case seh_errors::error_code_enum::in_page_error:
				return sig::errors::segmentation;
			case seh_errors::error_code_enum::breakpoint:
			case seh_errors::error_code_enum::single_step:
				return sig::errors::trap;
			case seh_errors::error_code_enum::datatype_misalignment:
				return sig::errors::bus;
			case seh_errors::error_code_enum::flt_denormal_operand:
			case seh_errors::error_code_enum::flt_divide_by_zero:
			case seh_errors::error_code_enum::flt_inexact_result:
			case seh_errors::error_code_enum::flt_invalid_operation:
			case seh_errors::error_code_enum::flt_overflow:
			case seh_errors::error_code_enum::flt_underflow:
			case seh_errors::error_code_enum::int_divide_by_zero:
			case seh_errors::error_code_enum::int_overflow:
				return sig::errors::arithmetic_exception;
			case seh_errors::error_code_enum::illegal_instruction:
			case seh_errors::error_code_enum::invalid_disposition:
			case seh_errors::error_code_enum::priv_instruction:
			case seh_errors::error_code_enum::noncontinuable_exception:
			case seh_errors::error_code_enum::status_unwind_consolidate:
				return sig::errors::illegal;
			case seh_errors::error_code_enum::invalid_handle:
				return sig::errors::pipe;
			default:
				return sig::errors::illegal;
		}
	}

	struct seh_error_category : std::error_category
	{
		const char* name() const noexcept override
		{ return "SEH"; }
		std::string message(int ev) const noexcept override
		{
#define SIGNAL_CASE(x) case sig::seh_errors::error_code_enum:: x: return #x;
			switch (ev)
			{
			SIGNAL_CASE(access_violation)
			SIGNAL_CASE(array_bounds_exceeded)
			SIGNAL_CASE(guard_page)
			SIGNAL_CASE(stack_overflow)
			SIGNAL_CASE(flt_stack_check)
			SIGNAL_CASE(in_page_error)
			SIGNAL_CASE(breakpoint)
			SIGNAL_CASE(single_step)
			SIGNAL_CASE(datatype_misalignment)
			SIGNAL_CASE(flt_denormal_operand)
			SIGNAL_CASE(flt_divide_by_zero)
			SIGNAL_CASE(flt_inexact_result)
			SIGNAL_CASE(flt_invalid_operation)
			SIGNAL_CASE(flt_overflow)
			SIGNAL_CASE(flt_underflow)
			SIGNAL_CASE(int_divide_by_zero)
			SIGNAL_CASE(int_overflow)
			SIGNAL_CASE(illegal_instruction)
			SIGNAL_CASE(invalid_disposition)
			SIGNAL_CASE(priv_instruction)
			SIGNAL_CASE(noncontinuable_exception)
			SIGNAL_CASE(status_unwind_consolidate)
			SIGNAL_CASE(invalid_handle)
			default: return "unknown";
			}
#undef SIGNAL_CASE
		}
		std::error_condition default_error_condition(int ev) const noexcept override
		{ return std::error_condition(map_exception_code(ev), sig_category()); }
	};
} // anonymous namespace

namespace seh_errors {

	std::error_code make_error_code(error_code_enum e)
	{
		return {static_cast<int>(e), seh_category()};
	}

} // namespace errors

std::error_category& seh_category()
{
	static seh_error_category seh_category;
	return seh_category;
}

#endif

} // namespace sig

