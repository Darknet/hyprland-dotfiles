package com.ejemplo.proyecto.utils

import java.text.SimpleDateFormat
import java.util.*

/**
 * Extensiones útiles para el proyecto
 */

/**
 * Extensión para String - verificar si es email válido
 */
fun String.isValidEmail(): Boolean {
    return android.util.Patterns.EMAIL_ADDRESS.matcher(this).matches()
}

/**
 * Extensión para Date - formatear fecha
 */
fun Date.formatTo(pattern: String): String {
    val formatter = SimpleDateFormat(pattern, Locale.getDefault())
    return formatter.format(this)
}

/**
 * Extensión para List - obtener elemento seguro
 */
fun <T> List<T>.safeGet(index: Int): T? {
    return if (index >= 0 && index < size) this[index] else null
}

/**
 * Extensión para Any - convertir a JSON string
 */
fun Any.toJsonString(): String {
    // Implementación básica - en proyecto real usar Gson/Moshi
    return this.toString()
}

/**
 * Extensión para String - convertir a snake_case
 */
fun String.toSnakeCase(): String {
    return this.replace(Regex("([a-z])([A-Z])"), "$1_$2").lowercase()
}

/**
 * Extensión para String - convertir a camelCase
 */
fun String.toCamelCase(): String {
    return this.split("_")
        .mapIndexed { index, word ->
            if (index == 0) word.lowercase()
            else word.replaceFirstChar { it.uppercase() }
        }
        .joinToString("")
}
