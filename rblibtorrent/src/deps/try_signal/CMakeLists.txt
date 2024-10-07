cmake_minimum_required(VERSION 2.8.12)
project(try_signal)

add_library(try_signal signal_error_code try_signal)
target_include_directories(try_signal PUBLIC .)

