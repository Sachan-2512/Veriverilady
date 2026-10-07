import sys
import serial

# Configuracion del puerto serie en Linux
BAUDRATE = 19200
# Ajustar segun: python3 -m serial.tools.list_ports -v
SERIAL_PORT = "/dev/ttyUSB0"

OPCODES = {
    'ADD': 0x20,
    'SUB': 0x22,
    'AND': 0x24,
    'OR':  0x25,
    'XOR': 0x26,
    'NOR': 0x27,
    'SRA': 0x03,
    'SRL': 0x02
}

EXIT_COMMANDS = {'q', 'e'}

class SerialPortControl:
    def __init__(self) -> None:
        try:
            self.serial_port = serial.Serial(
                port=SERIAL_PORT,
                baudrate=BAUDRATE,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=1,
                xonxoff=False,
                rtscts=False,
                dsrdtr=False,
            )
        except serial.SerialException as e:
            print(f"Error al abrir el puerto serie: {e}")
            sys.exit(1)

    def send_serial_data(self) -> None:
        # Mostrar mensajes de advertencia al usuario
        print("----------------------------------------------")
        print("Recordar presionar el botón de reset en placa antes de comenzar.")
        print("Revisar el dispositivo serie configurado.")
        print("----------------------------------------------")

        while True:
            operand1 = self.get_operand("Ingrese el primer byte de datos: ")
            operand2 = self.get_operand("Ingrese el segundo byte de datos: ")
            operation = self.get_operation()

            self.send_data(operation, operand1, operand2)
            self.receive_result()

    def get_operand(self, prompt: str) -> int:
        while True:
            operand_str: str = input(f'{prompt}').lower()
            if operand_str in EXIT_COMMANDS:
                self.exit_program()

            if len(operand_str) == 8 and all(c in '01' for c in operand_str):
                operand = int(operand_str, 2)
                if operand & 0x80:
                    operand -= 256
                return operand & 0xFF

            print('Error: por favor ingrese un numero binario de 8 bits.')

    def get_operation(self) -> int:
        while True:
            operation: str = input('Ingrese la operacion ... ADD, SUB, AND, OR, XOR, NOR, SRA, SRL : ').lower()
            if operation in EXIT_COMMANDS:
                self.exit_program()

            if operation.upper() in OPCODES:
                return OPCODES[operation.upper()]

            print('Operacion invalida')

    def send_data(self, operation: int, operand1: int, operand2: int) -> None:
        data_to_send: bytes = bytes([operand1, operand2, operation])
        self.serial_port.write(data_to_send)

    def receive_result(self) -> None:
        received_data: bytes = self.serial_port.read(1)
        if len(received_data) == 1:
            result: int = int.from_bytes(received_data, byteorder='big', signed=True)
            binary_result: str = f'{result & 0xFF:08b}'
            print(f'Resultado: {binary_result} ({result})')
        else:
            print('Error de recepcion: ningun dato recibido')

    def exit_program(self) -> None:
        print('Saliendo...')
        self.serial_port.close()
        sys.exit()

if __name__ == "__main__":
    app = SerialPortControl()
    app.send_serial_data()  # Ejecutar operaciones hasta ingresar un comando de salida

