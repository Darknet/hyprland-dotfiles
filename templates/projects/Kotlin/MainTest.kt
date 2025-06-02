package com.ejemplo.proyecto

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.assertThrows
import com.ejemplo.proyecto.utils.*

@DisplayName("Tests principales de la aplicación")
class MainTest {

    @Nested
    @DisplayName("Tests de extensiones de String")
    inner class StringExtensionsTest {

        @Test
        @DisplayName("Debe capitalizar palabras correctamente")
        fun `should capitalize words correctly`() {
            val input = "kotlin es genial"
            val expected = "Kotlin Es Genial"
            val result = input.capitalizeWords()
            
            assertEquals(expected, result)
        }

        @Test
        @DisplayName("Debe convertir a snake_case correctamente")
        fun `should convert to snake_case correctly`() {
            val input = "miVariableCamelCase"
            val expected = "mi_variable_camel_case"
            val result = input.toSnakeCase()
            
            assertEquals(expected, result)
        }

        @Test
        @DisplayName("Debe convertir a camelCase correctamente")
        fun `should convert to camelCase correctly`() {
            val input = "mi_variable_snake_case"
            val expected = "miVariableSnakeCase"
            val result = input.toCamelCase()
            
            assertEquals(expected, result)
        }
    }

    @Nested
    @DisplayName("Tests de Usuario")
    inner class UsuarioTest {

        private lateinit var usuario: Usuario

        @BeforeEach
        fun setUp() {
            usuario = Usuario("Juan", "juan@ejemplo.com", 25)
        }

        @Test
        @DisplayName("Debe crear usuario correctamente")
        fun `should create user correctly`() {
            assertEquals("Juan", usuario.nombre)
            assertEquals("juan@ejemplo.com", usuario.email)
            assertEquals(25, usuario.edad)
        }

        @Test
        @DisplayName("Debe verificar mayoría de edad correctamente")
        fun `should verify age correctly`() {
            assertTrue(usuario.esMayorDeEdad())
            
            val menor = Usuario("Ana", "ana@ejemplo.com", 16)
            assertFalse(menor.esMayorDeEdad())
        }
    }

    @Nested
    @DisplayName("Tests de operaciones matemáticas")
    inner class OperacionesTest {

        @Test
        @DisplayName("Debe sumar correctamente")
        fun `should add correctly`() {
            val operacion = Operacion.Suma(10, 5)
            val resultado = procesarOperacion(operacion)
            
            assertEquals(15, resultado)
        }

        @Test
        @DisplayName("Debe restar correctamente")
        fun `should subtract correctly`() {
            val operacion = Operacion.Resta(10, 5)
            val resultado = procesarOperacion(operacion)
            
            assertEquals(5, resultado)
        }

        @Test
        @DisplayName("Debe multiplicar correctamente")
        fun `should multiply correctly`() {
            val operacion = Operacion.Multiplicacion(10, 5)
            val resultado = procesarOperacion(operacion)
            
            assertEquals(50, resultado)
        }

        @Test
        @DisplayName("Debe dividir correctamente")
        fun `should divide correctly`() {
            val operacion = Operacion.Division(10, 5)
            val resultado = procesarOperacion(operacion)
            
            assertEquals(2, resultado)
        }

        @Test
        @DisplayName("Debe lanzar excepción al dividir por cero")
        fun `should throw exception when dividing by zero`() {
            val operacion = Operacion.Division(10, 0)
            
            assertThrows<IllegalArgumentException> {
                procesarOperacion(operacion)
            }
        }
    }
}
