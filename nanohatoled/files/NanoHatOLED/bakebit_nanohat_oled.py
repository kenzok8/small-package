#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# BakeBit example for the basic functions of BakeBit 128x64 OLED (http://wiki.friendlyarm.com/wiki/index.php/BakeBit_-_OLED_128x64)
#
# The BakeBit connects the NanoPi NEO and BakeBit sensors.
# You can learn more about BakeBit here:  http://wiki.friendlyarm.com/BakeBit
#
# Have a question about this example?  Ask on the forums here:  http://www.friendlyarm.com/Forum/
#
'''
## License

The MIT License (MIT)

BakeBit: an open source platform for connecting BakeBit Sensors to the NanoPi NEO.
Copyright (C) 2016 FriendlyARM

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
'''

from __future__ import print_function
import bakebit_128_64_oled as oled
from PIL import Image
from PIL import ImageFont
from PIL import ImageDraw
import time
import sys
import subprocess
import threading
import signal
import os
import socket
import fcntl
import struct

global width
width=128
global height
height=64

global pageCount
pageCount=2
global pageIndex
pageIndex=0
global showPageIndicator
showPageIndicator=False

global pageSleep
pageSleep=10
global pageSleepCountdown
pageSleepCountdown=pageSleep

oled.init()  #initialze SEEED OLED display
oled.setNormalDisplay()      #Set display to normal mode (i.e non-inverse mode)
oled.setHorizontalMode()

global drawing
drawing = False

global image
image = Image.new('1', (width, height))
global draw
draw = ImageDraw.Draw(image)
global fontb24
fontb24 = ImageFont.truetype('DejaVuSansMono-Bold.ttf', 24);
global font14
font14 = ImageFont.truetype('DejaVuSansMono.ttf', 14);
global smartFont
smartFont = ImageFont.truetype('DejaVuSansMono.ttf', 10);
global fontb14
fontb14 = ImageFont.truetype('DejaVuSansMono-Bold.ttf', 14);
global font11
font11 = ImageFont.truetype('DejaVuSansMono.ttf', 11);

global lock
lock = threading.Lock()

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def draw_page():
    global drawing
    global image
    global draw
    global oled
    global font
    global font14
    global smartFont
    global width
    global height
    global pageCount
    global pageIndex
    global showPageIndicator
    global width
    global height
    global lock
    global pageSleepCountdown

    lock.acquire()
    is_drawing = drawing
    page_index = pageIndex
    lock.release()

    if is_drawing:
        return

    #if the countdown is zero we should be sleeping (blank the display to reduce screenburn)
    if pageSleepCountdown == 1:
        oled.clearDisplay()
        pageSleepCountdown = pageSleepCountdown - 1
        return

    if pageSleepCountdown == 0:
        return

    pageSleepCountdown = pageSleepCountdown - 1

    lock.acquire()
    drawing = True
    lock.release()

    # Draw a black filled box to clear the image.
    draw.rectangle((0,0,width,height), outline=0, fill=0)
    # Draw current page indicator
    if showPageIndicator:
        dotWidth=4
        dotPadding=2
        dotX=width-dotWidth-1
        dotTop=(height-pageCount*dotWidth-(pageCount-1)*dotPadding)/2
        for i in range(pageCount):
            if i==page_index:
                draw.rectangle((dotX, dotTop, dotX+dotWidth, dotTop+dotWidth), outline=255, fill=255)
            else:
                draw.rectangle((dotX, dotTop, dotX+dotWidth, dotTop+dotWidth), outline=255, fill=0)
            dotTop=dotTop+dotWidth+dotPadding

    if page_index==0:
        text = time.strftime("%a %e %b %Y")
        draw.text((2,2),text,font=font14,fill=255)
        year=time.strftime('%Y')
        now=time.time()
        start_date=time.mktime(time.strptime(year, '%Y'))
        end_date=time.mktime(time.strptime(str(int(year)+1), '%Y'))
        percent=int((now-start_date)/(end_date-start_date)*1000)/10.0
        bar = int(round(percent/10, 0))
        text = bar * u'\u2593' + (10 - bar) * u'\u2591' + str(percent) + '%'
        draw.text((2,20),text,font=font14,fill=255)
        text = time.strftime("%X")
        draw.text((8,38),text,font=fontb24,fill=255)
    elif page_index==1:
        # Draw some shapes.
        # First define some constants to allow easy resizing of shapes.
        padding = 2
        top = padding
        bottom = height-padding
        # Move left to right keeping track of the current x position for drawing shapes.
        x = 0
        try:
            IPAddress = get_ip_address('eth0')
        except:
            IPAddress = get_ip()
        cmd = "cat /proc/loadavg| awk '{printf \"CPU Load: %.2f\", $(1)}'"
        CPU = subprocess.check_output(cmd, shell = True ).decode("utf-8", errors="ignore")
        cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.1f%%\", int($3/1024),int($2/1024),$3*100/$2 }'"
        MemUsage = subprocess.check_output(cmd, shell = True ).decode("utf-8", errors="ignore")
        cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
        Disk = subprocess.check_output(cmd, shell = True ).decode("utf-8", errors="ignore")
        tempI = int(open('/sys/class/thermal/thermal_zone0/temp').read());
        if tempI>1000:
            tempI = tempI/1000
        tempStr = u"CPU TEMP: %s\u00b0C" % int(tempI)

        draw.text((x+2, top),       "IP: " + str(IPAddress),  font=smartFont, fill=255)
        draw.text((x+2, top+12),    str(CPU), font=smartFont, fill=255)
        draw.text((x+2, top+24),    str(MemUsage),  font=smartFont, fill=255)
        draw.text((x+2, top+36),    str(Disk),  font=smartFont, fill=255)
        draw.text((x+2, top+48),    tempStr,   font=smartFont, fill=255)
    elif page_index==3: #shutdown -- no
        draw.text((2, 2),  'Shutdown?',  font=fontb14, fill=255)

        draw.rectangle((2,20,width-4,20+16), outline=0, fill=0)
        draw.text((4, 22),  'Yes',  font=font11, fill=255)

        draw.rectangle((2,38,width-4,38+16), outline=0, fill=255)
        draw.text((4, 40),  'No',  font=font11, fill=0)

    elif page_index==4: #shutdown -- yes
        draw.text((2, 2),  'Shutdown?',  font=fontb14, fill=255)

        draw.rectangle((2,20,width-4,20+16), outline=0, fill=255)
        draw.text((4, 22),  'Yes',  font=font11, fill=0)

        draw.rectangle((2,38,width-4,38+16), outline=0, fill=0)
        draw.text((4, 40),  'No',  font=font11, fill=255)

    elif page_index==5:
        draw.text((2, 2),  'Shutting down',  font=fontb14, fill=255)
        draw.text((2, 20),  'Please wait',  font=font11, fill=255)

    oled.drawImage(image)

    lock.acquire()
    drawing = False
    lock.release()


def is_showing_power_msgbox():
    global pageIndex
    lock.acquire()
    page_index = pageIndex
    lock.release()
    if page_index==3 or page_index==4:
        return True
    return False


def update_page_index(pi):
    global pageIndex
    lock.acquire()
    pageIndex = pi
    lock.release()

def receive_signal(signum, stack):
    global pageIndex
    global pageSleepCountdown
    global pageSleep

    pageSleepCountdown = pageSleep #user pressed a button, reset the sleep counter

    lock.acquire()
    page_index = pageIndex
    lock.release()

    if page_index==5:
        return

    if signum == signal.SIGUSR1:
        print('K1 pressed')
        if is_showing_power_msgbox():
            if page_index==3:
                update_page_index(4)
            else:
                update_page_index(3)
            draw_page()
        else:
            pageIndex=0
            draw_page()

    if signum == signal.SIGUSR2:
        print('K2 pressed')
        if is_showing_power_msgbox():
            if page_index==4:
                update_page_index(5)
                draw_page()

            else:
                update_page_index(0)
                draw_page()
        else:
            update_page_index(1)
            draw_page()

    if signum == signal.SIGALRM:
        print('K3 pressed')
        if is_showing_power_msgbox():
            update_page_index(0)
            draw_page()
        else:
            update_page_index(3)
            draw_page()


image0 = Image.open('logo.png').convert('1')
oled.drawImage(image0)
time.sleep(2)

signal.signal(signal.SIGUSR1, receive_signal)
signal.signal(signal.SIGUSR2, receive_signal)
signal.signal(signal.SIGALRM, receive_signal)

while True:
    try:
        draw_page()

        lock.acquire()
        page_index = pageIndex
        lock.release()

        if page_index==5:
            time.sleep(2)
            while True:
                lock.acquire()
                is_drawing = drawing
                lock.release()
                if not is_drawing:
                    lock.acquire()
                    drawing = True
                    lock.release()
                    oled.clearDisplay()
                    break
                else:
                    time.sleep(.1)
                    continue
            time.sleep(1)
            os.system('poweroff')
            break
        time.sleep(1)
    except KeyboardInterrupt:
        break
    except IOError:
        print ("Error")
