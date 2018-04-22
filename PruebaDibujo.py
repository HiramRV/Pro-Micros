# -*- coding: utf-8 -*-
"""
Created on Thu Apr 12 10:24:56 2018

@author: Andrea Maybell
"""
#Importar librerías
import tkinter as tk
import numpy as np
import serial
import time

#Dimensiones del área de dibujo
canvas_width = 400
canvas_height = 400

#Variables globales
#LISTAS
global listX #puntos en X
listX=[0]
global listY #puntos en Y
listY=[0]
global listA #ángulos alfa
listA=[0]
global listB #ángulos beta
listB=[0]
global listI #instrucciones
listI=[0]
global listP #porcentaje de avance
listP=[0]
global Lista #lista a enviar al PIC
Lista=[0]
global ListaD #lista Demo
ListaD=[0]
#BANDERAS
global control  #0 no cambia, 1 cambio de control 
control=0
global marcador #0 marcador arriba, 1 marcador abajo
marcador=0

#Inicializar puerto
ser= serial.Serial()
ser.baudrate = 300
ser.port= 'COM3'
ser.stopbits=1
ser.timeout=1

#Largo relativo del brazo 
a=260

"""
paint
Descripción: dibujar mediante óvalos con el cursor
Parámetros: event
Salida: listA
"""
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
        if((abs(listX[-1]-x1)<6) or (abs(listY[-1]-yn)<6)): #si la distancia entre un punto y el siguiente es menor a 6 pixeles
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
        
"""
radsAgrads
Descripción: conversión de radianes a grados
Parámetros: x (número a convertir)
Salida: conversión 
"""
def radsAgrads(x):
    return 180*x/np.pi

"""
Coord
Descripción: Muestra los ángulos en la consola
Parámetros: NINGUNO
Salida: NINGUNA
"""   
def Coord():
    print("A",listA)
    print("B",listB)

"""
Alfa
Descripción: Encuentra el ángulo Alfa
Parámetros: x (coordenada x), y (coordenada y)
Salida: alfa mapeado para el PIC
"""
def Alfa(x,y):
    teta= np.arctan(y/x)
    b= np.sqrt((x**2)+(y**2))
    arg= b/(2*a)
    phi= np.arccos(arg)
    alfa= teta+phi
    return APic(radsAgrads(alfa))

"""
Beta
Descripción: Encuentra el ángulo Beta
Parámetros: x (coordenada x), y (coordenada y)
Salida: beta mapeado para el PIC
"""    
def Beta(x,y):
    b= np.sqrt((x**2)+(y**2))
    beta= np.arccos(((2*(x**2))-(b**2))/(2*(a**2)))
    return APic(radsAgrads(beta))

"""
APic
Descripción: Mapea un ángulo para los valores de CCPRxL en el PIC
Parámetros: a (ángulo a mapear)
Salida: ángulo mapeado para el PIC
"""
def APic(a):
    if(a<0):
        a=0
    return int((a/5.625)//1)+32 #mapeo a pic, movimientos de 5.625°

"""
instrucción
Descripción: Define la instrucción a realizar 
Parámetros: var (variable para subir o bajar), con (variable de cambio de control)
Salida: inst (instrucción para el PIC)
"""
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

"""
armarLista
Descripción: Forma la lista en el orden que el PIC espera recibir los datos
Parámetros: NINGUNO
Salida: Lista (Lista ordenada)
"""
def armarLista():
    print("ARM")
    Porcentaje()
    n=0
    for n in range(len(listI)-1):
        Lista.append(64)
        Lista.append(listI[n])
        Lista.append(listA[n])
        Lista.append(listB[n])
        Lista.append(listP[n])
    return Lista

"""
Dibujar
Descripción: Envía datos al PIC
Parámetros: NINGUNO
Salida: NINGUNA
"""      
def Dibujar():
    print(listI)
    print(listA)
    print(listB)
    lista= armarLista()
    print(listP)
    print(lista)
#    x=0
#    ser.open()
#    for x in range(len(lista)-1):
#        ser.write(chr(lista[x]).encode())
#        ser.write(chr(lista[x+1]).encode())
#        ser.write(chr(lista[x+2]).encode())
#        ser.write(chr(lista[x+3]).encode())
#        ser.write(chr(lista[x+4]).encode())
#        time.sleep(1)
#        x= x+5
#    print(lista)
#    ser.close()

"""
Porcentaje
Descripción: Forma una lista para indicar el "porcentaje" de progreso del dibujo
Parámetros: NINGUNO
Salida: listP (lista de porcentajes )
"""
def Porcentaje():
    global listX
    global listP
    totalP= len(listX)
    tot= totalP-1
    p= tot//7
    print("P", p)
    print("largo X",totalP)
    n=0
    for n in range(p):
        listP.append(0)
    n=0
    for n in range(p):
        listP.append(1)
    n=0
    for n in range(p):
        listP.append(3)
    n=0
    for n in range(p):
        listP.append(7)
    n=0
    for n in range(p):
        listP.append(15)
    n=0
    for n in range(p):
        listP.append(31)
    n=0
    for n in range(p):
        listP.append(63)
    ult= tot-(p*7)
    n=0
    for n in range(ult):
        listP.append(127)
    print("largo P", len(listP))
    return listP

"""
Borrar
Descripción: Limpia el Canvas para un nuevo dibujo y limpia las listas 
Parámetros: NINGUNO
Salida: NINGUNA
"""
def Borrar():
    w.delete("all")
    global listX
    global listY
    global listA
    global listB
    global listI
    global listP
    global Lista
    listX=[0]
    listY=[0]
    listA=[0]
    listB=[0]
    listI=[0]    
    listP=[0]
    Lista=[0]
    
"""
MDemo
Descripción: Muestra el dibujo guardado como demo
Parámetros: NINGUNO
Salida: NINGUNA
"""
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

"""
GDemo
Descripción: Guarda el dibujo en el canvas como demo
Parámetros: NINGUNO
Salida: NINGUNA
"""
def GDemo():
    global listX
    global listY
    global listI
    global listA
    global listB
    global ListaD
    ListaD=[listX,listY,listI,listA,listB]

"""
cambio
Descripción: Cambia el control de manual a por computadora y viceversa
Parámetros: NINGUNO
Salida: NINGUNA
"""
def cambio():
    global control
    if (control==0):
        control=1
        b6.config(bg="plum")
    else:
        control=0
        b6.config(bg="peachpuff")
    
    
#INTERFAZ GRÁFICA
        
#Ventana principal
master = tk.Tk()
master.geometry("520x480")
master.resizable(0,0)
master.title( "Dibuja" )
master.configure(bg="dim gray")

#Canvas para dibujar
w = tk.Canvas(master, width=canvas_width, height=canvas_height, bg="white", bd=2)
w.place(x=5,y=5)
w.bind( "<B1-Motion>", paint )

message = tk.Label( master, text = "Presiona y arrastra el mouse para dibujar",font="Calibri 10 bold", bg="black", fg="white" )
message.place(x=90,y=canvas_height+20)

#Botones
b1= tk.Button(master, text="Mostrar coordenadas", command=Coord, font="Calibri 10 bold")
b1.place(x=142,y=canvas_height+50)
b2= tk.Button(master, text="Dibujar", command=Dibujar, font="Impact 14", bg="hot pink")
b2.place(x=canvas_width+30, y=20)
b3= tk.Button(master, text="Borrar", command=Borrar, font="Impact 12")
b3.place(x=canvas_width+40, y=65)
b4= tk.Button(master, text="Mostrar Demo", command=MDemo, font="Calibri 10 bold", bg="skyblue")
b4.place(x=canvas_width+20, y=380)
b5= tk.Button(master, text="Guardar Demo", command=GDemo, font="Calibri 10 bold", bg="light green")
b5.place(x=canvas_width+20, y=350)
b6= tk.Button(master, text="Cambio de modo", command=cambio, font="Calibri 10 bold")
b6.place(x=canvas_width+15,y=200)

 
master.mainloop()

# Código para implementación de dibujar en patalla obtenido en:
# Bernd Klein (2018) Python Tkinter Course. En: https://www.python-course.eu/tkinter_canvas.php