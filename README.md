# SEII-practica-1
void rtos_start_scheduler(void)
{
#ifdef RTOS_ENABLE_IS_ALIVE
	init_is_alive();
#endif

	task_list.global_tick = 0;
	task_list.current_task = -1;
	SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk | SysTick_CTRL_TICKINT_Msk
	        | SysTick_CTRL_ENABLE_Msk;
	reload_systick();
	rtos_create_task(idle_task,0,kAutoStart);
//	NVIC_SetPriority(PendSV_IRQn, 0xFF);/////////////////////
	//reload_systick();
	for (;;)
		;
}

rtos_task_handle_t rtos_create_task(void (*task_body)(), uint8_t priority,
		rtos_autostart_e autostart)
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

rtos_tick_t rtos_get_clock(void)
{
	return task_list.global_tick;
}

void rtos_delay(rtos_tick_t ticks)
{
	task_list.tasks[task_list.current_task].state = S_WAITING;
	task_list.tasks[task_list.current_task].local_tick = ticks;
	dispatcher(kFromNormalExec);
}

void rtos_suspend_task(void)
{
	task_list.tasks[task_list.current_task].state = S_SUSPENDED;
	dispatcher(kFromNormalExec);
}

void rtos_activate_task(rtos_task_handle_t task)
{
	task_list.tasks[task].state = S_READY;
	dispatcher(kFromNormalExec);
}

/**********************************************************************************/
// Local methods implementation
/**********************************************************************************/

static void reload_systick(void)
{
	SysTick->LOAD = USEC_TO_COUNT(RTOS_TIC_PERIOD_IN_US,
	        CLOCK_GetCoreSysClkFreq());
	SysTick->VAL = 0;
}

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

/**********************************************************************************/
// IDLE TASK
/**********************************************************************************/

static void idle_task(void)
{
	for (;;)
	{
		//PRINTF("pelaste");
	}
}

/****************************************************/
// ISR implementation
/****************************************************/

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

void PendSV_Handler(void)
{
	  register int32_t r0 asm("r0");
	  (void) r0;
	  SCB->ICSR |= SCB_ICSR_PENDSVCLR_Msk;
	  r0 = (int32_t) task_list.tasks[task_list.current_task].sp;
	  asm("mov r7,r0");
}
