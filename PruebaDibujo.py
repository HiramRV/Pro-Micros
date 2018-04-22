# -*- coding: utf-8 -*-
"""
Created on Thu Apr 12 10:24:56 2018

@author: Andrea Maybell
"""

import tkinter as tk
import numpy as np
import serial
import time

canvas_width = 255
canvas_height = 255

global listX
listX=[0]
global listY
listY=[0]
global listA
listA=[0]
global listB
listB=[0]
global listI
listI=[0]
global Lista
Lista=[0]
global ListaD
ListaD=[0]

ser= serial.Serial()
ser.baudrate = 300
ser.port= 'COM3'
ser.stopbits=1
ser.timeout=1

a=130
#var=0

global control  
control=0
global marcador
marcador=0

def paint( event ):
    #control con interfaz
    if(event.x>=0 and event.x<canvas_width and event.y<canvas_height and event.y>=0):
        x=event.x
        y=event.y
        x1, y1 = ( event.x - 4 ), ( event.y - 4 )
        x2, y2 = ( event.x + 4 ), ( event.y + 4 )
        w.create_oval( x1, y1, x2, y2, fill = "black" )
        yn= abs(y-canvas_height)
        a= Alfa(x1,yn)
        b= Beta(x1,yn)
        if((abs(listX[-1]-x1)<6) or (abs(listY[-1]-yn)<6)):
            I= listI[-1]
            listX.append(x)
            listY.append(yn)
            listI.append(I)
            listA.append(a)
            listB.append(b)
        else:
            global control
            global marcador
            marcador=0
            I=instruccion(marcador,control)
            listX.append(x)
            listY.append(yn)
            listI.append(I)    
            listA.append(a)
            listB.append(b)             #Subir marcador en coordenada anterior
#                listX.append(listX[-1])
#                listY.append(listY[-1])
#                listI.append(I)   
#                listA.append(listA[-1])
#                listB.append(listB[-1])     
            marcador=1
            I=instruccion(marcador,control)
            listX.append(x)
            listY.append(yn)
            listI.append(I)    
            listA.append(a)
            listB.append(b)             #Bajar marcador en coordenada nueva
    else:
        print("fuera del cuadrante")
    return listA
        

def radsAgrads(x):
    return 180*x/np.pi
    
def Coord():
    print("A",listA)
    print("B",listB)

def Alfa(x,y):
    teta= np.arctan(y/x)
    b= np.sqrt((x**2)+(y**2))
    arg= b/(2*a)
    phi= np.arccos(arg)
    alfa= teta+phi
    return APic(radsAgrads(alfa))
    
def Beta(x,y):
    b= np.sqrt((x**2)+(y**2))
    beta= np.arccos(((2*(x**2))-(b**2))/(2*(a**2)))
    return APic(radsAgrads(beta))

def APic(a):
    if(a<0):
        a=0
    return int((a/5.625)//1)+32 #mapeo a pic, movimientos de 5.625°

def instruccion(var,con):
    if(con==0):
        inst=0
    else:
        inst=1 #cambio de control 
    if(var==1):
        inst=2+inst #bajar marcador
        
#        esto forma el siguiente listado de instrucciones:
#        00 control interfaz sin cambiar modo
#        01 control manual 
#        10 control interfaz cambiar modo
#        11 control manual con marcador abajo
    return inst

def armarLista():
    print("ARM")
    n=0
    for n in range(len(listI)-1):
        Lista.append(64)
        Lista.append(listI[n])
        Lista.append(listA[n])
        Lista.append(listB[n])
    return Lista

        
def Dibujar():
    print(listI)
    print(listA)
    print(listB)
    lista= armarLista()
    print(lista)
#    x=0
#    ser.open()
#    for x in range(len(lista)):
#        ser.write(chr(lista[x]).encode())
#        ser.write(chr(lista[x+1]).encode())
#        ser.write(chr(lista[x+2]).encode())
#        ser.write(chr(lista[x+3]).encode())
#        time.sleep(1)
#        x= x+4
#    print(lista)
#    ser.close()

def Borrar():
    w.delete("all")
    global listX
    global listY
    global listA
    global listB
    global listI
    global Lista
    listX=[0]
    listY=[0]
    listA=[0]
    listB=[0]
    listI=[0]       
    Lista=[0]
    
def MDemo():
    global ListaD
    global listI
    global listA
    global listB
    
    print("Demo", ListaD)
    X= ListaD[0]
    Y= ListaD[1]
    x=0
    for x in range(len(X)-1):
        w.create_oval(X[x]-4, abs(Y[x]-canvas_height)-4, X[x]+4, abs(Y[x]-canvas_height)+4, fill = "black" )
    
    listI= ListaD[2]
    listA= ListaD[3]
    listB= ListaD[4]

def GDemo():
    global listX
    global listY
    global listI
    global listA
    global listB
    global ListaD
    ListaD=[listX,listY,listI,listA,listB]
    
    

master = tk.Tk()
master.title( "Dibuja" )
w = tk.Canvas(master, 
           width=canvas_width, 
           height=canvas_height)
w.pack(expand = "yes", fill = "both")
w.bind( "<B1-Motion>", paint )
#w.bind("<Leave>", draw)

message = tk.Label( master, text = "Presiona y arrastra el mouse para dibujar" )
message.pack( side = "top" )

b1= tk.Button(master, text="Mostrar coordenadas", command=Coord)
b1.pack(side="bottom")
b2= tk.Button(master, text="Dibujar", command=Dibujar)
b2.pack(side="left")
b3= tk.Button(master, text="Borrar", command=Borrar)
b3.pack(side="right")
b4= tk.Button(master, text="Mostrar Demo", command=MDemo)
b4.pack(side="right")
b5= tk.Button(master, text="Guardar Demo", command=GDemo)
b5.pack(side="left")

#var= var+1
 
master.mainloop()

# Código para implementación de dibujar en patalla obtenido en:
# Bernd Klein (2018) Python Tkinter Course. En: https://www.python-course.eu/tkinter_canvas.php