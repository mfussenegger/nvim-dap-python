import multiprocessing
import time


def foo():
    time.sleep(0.100)
    return 42


def main():
    p1 = multiprocessing.Process(target=foo)
    p1.start()

    p2 = multiprocessing.Process(target=foo)
    p2.start()

    p1.join()
    p2.join()


main()
