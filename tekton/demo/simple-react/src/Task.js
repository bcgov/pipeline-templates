import React from 'react'

export default function Task( { task, toggleTask } ) {
    function handleTask(){
        toggleTask(task.id)
    }
    return (
        <div>
            <label>
                <input className="checkbox" type="checkbox" checked={task.complete} 
                onChange={handleTask} />
                {task.name}
            </label>
        </div>
    )
}
