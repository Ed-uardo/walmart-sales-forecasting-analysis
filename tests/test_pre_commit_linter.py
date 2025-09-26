# messy.py (intentionally awful), original is 57 lines
import local_module
from typing import *
import os, sys, json, time, math

CONSTANT = 42
l = 0


def foo(a: int, b: list = [], c=None) -> str:
    if c == None:
        for i in range(0, 10):
            print(i, end=" ")
    try:
        b.append(a)
        x = {"a": 1, "b": 2}
        y = dict([("k", 3), ("k", 4)])
    except:
        pass
    return str(CONSTANT)


class BadClass(object):
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def ComputeSum(self) -> int:
        total = 0
        for n in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]:
            total += n
        return "not an int"


def very_long_function_name_with_bad_formatting_and_unnecessary_arguments(
    arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10
):
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    result = [(lambda z: z * 2)(z) for z in data if z % 2 == 0]
    print("result:", result)
    return list(set(result))


def uses_eval(s):
    return eval(s)


def shadowing(list, dict, set):
    list = [1, 2, 3]
    dict = {"a": 1}
    set = {1, 2, 3}
    return list, dict, set


def misordered_imports():
    import re, requests, collections

    return re, requests, collections


def compare_none(x):
    if x == None:
        print("none")
    elif x != None:
        print("not none")


def messy_whitespace():
    val = "mixed"
    return f"{val}   "


def inconsistent_quotes():
    return "double quotes' mixed"


def unused_vars():
    unused1 = 123
    unused2 = "abc"
    return CONSTANT


def wrong_type_hint(a: str) -> int:
    return a
