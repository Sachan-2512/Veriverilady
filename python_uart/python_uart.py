#ls -l /dev/ttyUSB*
#sudo dmesg | tail -n 50
#python3 -m serial.tools.list_ports -v

import serial


# Configuración UART

PORT = "/dev/ttyUSB1"
BAUDRATE = 19200


# Comandos de la Interface

CMD_DATA_A     = 0x00
CMD_DATA_B     = 0x01
CMD_GET_RESULT = 0x02
CMD_OPERATOR   = 0x03


# Opcodes de la ALU

OP_ADD = 0b100000
OP_SUB = 0b100010
OP_AND = 0b100100
OP_OR  = 0b100101
OP_XOR = 0b100110
OP_SRA = 0b000011
OP_SRL = 0b000010
OP_NOR = 0b100111


# Diccionario para relacionar nombre -> opcode

OPERATIONS = {
    "ADD": OP_ADD,
    "SUB": OP_SUB,
    "AND": OP_AND,
    "OR":  OP_OR,
    "XOR": OP_XOR,
    "SRA": OP_SRA,
    "SRL": OP_SRL,
    "NOR": OP_NOR
}


# Funcion para enviar un byte

def send_byte(ser, value):
    ser.write(bytes([value]))


# Funcion para ejecutar una operacion de ALU

def operation_ALU(ser, operator, a, b):

    # Enviar operador
    send_byte(ser, CMD_OPERATOR)
    send_byte(ser, operator)

    # Enviar A
    send_byte(ser, CMD_DATA_A)
    send_byte(ser, a)

    # Enviar B
    send_byte(ser, CMD_DATA_B)
    send_byte(ser, b)

    # Pedir resultado
    send_byte(ser, CMD_GET_RESULT)

    # Esperar 1 byte de respuesta
    response = ser.read(1)

    if len(response) == 0:
        raise TimeoutError("La FPGA no respondió")

    return response[0]


def main():

    ser = serial.Serial(
        port=PORT,
        baudrate=BAUDRATE,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=1
    )

    try:

        # ==========================================
        # Ingreso de datos
        # ==========================================

        A = int(input("Ingrese A (0-255): "))

        operation = input(
            "Ingrese operacion "
            "[ADD, SUB, AND, OR, XOR, NOR, SRA, SRL]: "
        ).upper()

        B = int(input("Ingrese B (0-255): "))


        # ==========================================
        # Validaciones
        # ==========================================

        if A < 0 or A > 255:
            print("ERROR: A debe estar entre 0 y 255")
            return

        if B < 0 or B > 255:
            print("ERROR: B debe estar entre 0 y 255")
            return

        if operation not in OPERATIONS:
            print("ERROR: operacion invalida")
            return


        # Buscamos opcode correspondiente
        opcode = OPERATIONS[operation]


        # ==========================================
        # Ejecutar operación en la FPGA
        # ==========================================

        result = operation_ALU(
            ser,
            opcode,
            A,
            B
        )

        print()
        print("==============================")
        print(f"A         = {A:3d} ({A:08b})")
        print(f"Operacion = {operation}")
        print(f"B         = {B:3d} ({B:08b})")
        print("------------------------------")
        print(f"Resultado = {result:3d} ({result:08b})")
        print("==============================")


        # ==========================================
        # Mostrar resultado
        # ==========================================

        print()
        print("==========================")
        print(f"A         = {A}")
        print(f"Operacion = {operation}")
        print(f"B         = {B}")
        print("--------------------------")
        print(f"Resultado = {result}")
        print("==========================")


    except ValueError:

        print("ERROR: A y B deben ser numeros enteros")


    except TimeoutError as error:

        print(f"ERROR: {error}")


    finally:

        ser.close()


if __name__ == "__main__":
    main()