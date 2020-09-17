################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../device/system_MK66F18.c 

OBJS += \
./device/system_MK66F18.o 

C_DEPS += \
./device/system_MK66F18.d 


# Each subdirectory must supply rules for building sources it contributes
device/%.o: ../device/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MCU C Compiler'
	arm-none-eabi-gcc -D__REDLIB__ -DCPU_MK66FN2M0VMD18 -DCPU_MK66FN2M0VMD18_cm4 -DFSL_RTOS_BM -DSDK_OS_BAREMETAL -DSERIAL_PORT_TYPE_UART=1 -DSDK_DEBUGCONSOLE=1 -DCR_INTEGER_PRINTF -DPRINTF_FLOAT_ENABLE=0 -D__MCUXPRESSO -D__USE_CMSIS -DDEBUG -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/board" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/source" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/drivers" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/device" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/CMSIS" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/component/uart" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/utilities" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/component/serial_manager" -I"/home/ethan/Documents/SEI2/Practica1/MK66FN2M0xxx18_Project/component/lists" -O0 -fno-common -g3 -Wall -c -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fmerge-constants -fmacro-prefix-map="../$(@D)/"=. -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -D__REDLIB__ -fstack-usage -specs=redlib.specs -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.o)" -MT"$(@:%.o=%.d)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


