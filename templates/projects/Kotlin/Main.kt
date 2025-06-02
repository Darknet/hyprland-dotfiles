package com.ejemplo.proyecto

import kotlinx.coroutines.*
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

/**
 * Aplicación principal de Kotlin
 * 
 * @author Tu Nombre
 * @version 1.0.0
 */
fun main() = runBlocking {
    println("🚀 ¡Hola, mundo desde Kotlin!")
    println("📅 Fecha actual: ${getCurrentDateTime()}")
    
    // Ejemplo de corrutinas
    launch {
        delay(1000)
        println("⏰ Mensaje después de 1 segundo")
    }
    
    // Ejemplo de funciones de extensión
    val mensaje = "kotlin es genial"
    println("📝 Mensaje capitalizado: ${mensaje.capitalizeWords()}")
    
    // Ejemplo de data class
    val usuario = Usuario("Juan", "juan@ejemplo.com", 25)
    println("👤 Usuario: $usuario")
    
    // Ejemplo de sealed class
    val resultado = procesarOperacion(Operacion.Suma(10, 5))
    println("🔢 Resultado: $resultado")
    
    delay(2000) // Esperar a que termine la corrutina
}

/**
 * Obtiene la fecha y hora actual formateada
 */
fun getCurrentDateTime(): String {
    val now = LocalDateTime.now()
    val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss")
    return now.format(formatter)
}

/**
 * Función de extensión para capitalizar palabras
 */
fun String.capitalizeWords(): String {
    return this.split(" ")
        .joinToString(" ") { word ->
            word.replaceFirstChar { 
                if (it.isLowerCase()) it.titlecase() else it.toString() 
            }
        }
}

/**
 * Data class para representar un usuario
 */
data class Usuario(
    val nombre: String,
    val email: String,
    val edad: Int
) {
    fun esMayorDeEdad(): Boolean = edad >= 18
}

/**
 * Sealed class para operaciones matemáticas
 */
sealed class Operacion {
    data class Suma(val a: Int, val b: Int) : Operacion()
    data class Resta(val a: Int, val b: Int) : Operacion()
    data class Multiplicacion(val a: Int, val b: Int) : Operacion()
    data class Division(val a: Int, val b: Int) : Operacion()
}

/**
 * Procesa una operación matemática
 */
fun procesarOperacion(operacion: Operacion): Int {
    return when (operacion) {
        is Operacion.Suma -> operacion.a + operacion.b
        is Operacion.Resta -> operacion.a - operacion.b
        is Operacion.Multiplicacion -> operacion.a * operacion.b
        is Operacion.Division -> {
            if (operacion.b != 0) operacion.a / operacion.b
            else throw IllegalArgumentException("División por cero")
        }
    }
}
