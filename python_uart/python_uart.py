#ls -l /dev/ttyUSB*
#sudo dmesg | tail -n 50
#python3 -m serial.tools.list_ports -v

import serial



# Configuración UART


PORT = "/dev/ttyUSB0"   # CAMBIAR según lo que aparezca
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

        A = 5
        B = 3

        result = operation_ALU(
            ser,
            OP_ADD,
            A,
            B
        )

        print(f"A = {A}")
        print(f"B = {B}")
        print("Operacion = ADD")

        print(
            f"Resultado recibido = {result}"
        )

        if result == 8:
            print("TEST OK")
        else:
            print(
                f"TEST ERROR: esperado 8, recibido {result}"
            )

    finally:

        ser.close()


if __name__ == "__main__":
    main()