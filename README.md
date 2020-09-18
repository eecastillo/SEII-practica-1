# SEII-practica-1
## Inicialización del sistema operativo
Dentro de esta funcion se añadió:
* Configurar el reloj global a 0
* Crear la tarea correspondiente al idle_task
* Asignar el current_task a -1 para uso dentro del calendarizador
```
void rtos_start_scheduler(void)
{
	task_list.global_tick = 0;
	task_list.current_task = -1;
	SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk | SysTick_CTRL_TICKINT_Msk
		| SysTick_CTRL_ENABLE_Msk;
	reload_systick();
	rtos_create_task(idle_task,0,kAutoStart);
	//reload_systick();
	for (;;)
		;
}
```
## Creación de tareas
Se asignan las prioridades correspondientes a la nueva tarea a crear
* Apuntador a la tarea
* Prioridad de la tarea
* Estado de la tarea dependiendo del parametro autostart
* Se asigna el stack
* Local tick se asigna a 0
* Se suma el numero de nTasks
```
rtos_task_handle_t rtos_create_task(void (*task_body)(), uint8_t priority,rtos_autostart_e autostart)
{
	if(RTOS_MAX_NUMBER_OF_TASKS > task_list.nTasks)
	{
		task_list.tasks[task_list.nTasks].task_body = task_body;
		task_list.tasks[task_list.nTasks].priority = priority;
		if(kAutoStart == autostart)
		{
			task_list.tasks[task_list.nTasks].state = S_READY;
		}
		else
		{
			task_list.tasks[task_list.nTasks].state = S_SUSPENDED;
		}
		task_list.tasks[task_list.nTasks].sp = &(task_list.tasks[task_list.nTasks].stack[RTOS_STACK_SIZE-1]) - STACK_FRAME_SIZE;
		task_list.tasks[task_list.nTasks].stack[RTOS_STACK_SIZE - STACK_LR_OFFSET] = (uint32_t) task_body;
		task_list.tasks[task_list.nTasks].stack[RTOS_STACK_SIZE - STACK_PSR_OFFSET] = (STACK_PSR_DEFAULT);
		task_list.tasks[task_list.nTasks].local_tick = 0;
		task_list.nTasks++;
		return task_list.nTasks;
	}
	return -1;
}
```
## Obtención del valor del reloj del sistema
* Se retorna el valor del tick global ubicado dentro de task list
```
rtos_tick_t rtos_get_clock(void)
{
	return task_list.global_tick;
}
```
## Delay para dormir la tarea durante un tiempo
* Se pone en modo de espera la tarea actual.
* Ae le asigna el numero de ticks con los que se llamó a la función.
* Se llama al calendarizador en modo de ejecución normal.
```
void rtos_delay(rtos_tick_t ticks)
{
	task_list.tasks[task_list.current_task].state = S_WAITING;
	task_list.tasks[task_list.current_task].local_tick = ticks;
	dispatcher(kFromNormalExec);
}
```
## Suspender la tarea
* Se asigna el estado de la tarea a suspendido.
* Se manda a llamar el calendarizador con modo de ejecución normal.
```
void rtos_suspend_task(void)
{
	task_list.tasks[task_list.current_task].state = S_SUSPENDED;
	dispatcher(kFromNormalExec);
}
```
## Activar la tarea
* Se asigna el estado de la tarea a listo.
* Se llama al calendarizador con modo de ejecución normal.
```
void rtos_activate_task(rtos_task_handle_t task)
{
	task_list.tasks[task].state = S_READY;
	dispatcher(kFromNormalExec);
}
```
##
```
static void dispatcher(task_switch_type_e type)
{
	rtos_task_handle_t next_task = task_list.nTasks-1;
	 int8_t maxPriority = -1;

	for(uint8_t i = 0; i < task_list.nTasks; i++)
	{
		if(maxPriority < task_list.tasks[i].priority && (S_READY == task_list.tasks[i].state || S_RUNNING == task_list.tasks[i].state))
		{
			maxPriority = task_list.tasks[i].priority;
			next_task = i;
		}
	}

	task_list.next_task = next_task;
	if(task_list.next_task != task_list.current_task)
	{
		context_switch(type);
	}
}
```
```
FORCE_INLINE static void context_switch(task_switch_type_e type)
{
	register uint32_t r0 asm("sp");
  	(void) r0;
	static uint8_t first = 1;
	if(!first)
	{
		asm("mov r0, r7");
		task_list.tasks[task_list.current_task].sp = (uint32_t*) r0;
		if(kFromNormalExec == type)
		{
		//	task_list.tasks[task_list.current_task].sp -= (9);
		task_list.tasks[task_list.current_task].sp -=STACK_FRAME_SIZE+1;
			//task_list.tasks[task_list.current_task].state = S_READY;
		}
		else
		{
			//task_list.tasks[task_list.current_task].sp -= (9);
			task_list.tasks[task_list.current_task].sp -= -(STACK_FRAME_SIZE-1)-2;
		}
	}
	else
	{
		first = 0;
	}
	task_list.current_task = task_list.next_task;
	task_list.tasks[task_list.current_task].state = S_RUNNING;
	SCB->ICSR |= SCB_ICSR_PENDSVSET_Msk;
}
```
```
static void activate_waiting_tasks()
{
	for(uint8_t i = 0; i < task_list.nTasks; i++)
	{
		if(S_WAITING == task_list.tasks[i].state)
		{
			task_list.tasks[i].local_tick--;
			if(0 == task_list.tasks[i].local_tick)
			{
				//task_list.tasks[i].state = S_READY;
				rtos_activate_task(i);
			}
		}
	}
}
```
```
void SysTick_Handler(void)
{

#ifdef RTOS_ENABLE_IS_ALIVE
	refresh_is_alive();
#endif
	task_list.global_tick++;
	activate_waiting_tasks();
	reload_systick();
	dispatcher(kFromISR);
}
```
```
void PendSV_Handler(void)
{
	  register int32_t r0 asm("r0");
	  (void) r0;
	  SCB->ICSR |= SCB_ICSR_PENDSVCLR_Msk;
	  r0 = (int32_t) task_list.tasks[task_list.current_task].sp;
	  asm("mov r7,r0");
}
```
