import {useState, useRef, useEffect} from 'react'
import Checklist from './Checklist'

const LOCAL_STORAGE_KEY = 'checklist'

function App() {
  const [tasks, setTasks] = useState([])
  const taskRef = useRef()
  
  useEffect(() => {
    const storedTask = JSON.parse(localStorage.getItem
      (LOCAL_STORAGE_KEY))
    if (storedTask) setTasks(storedTask)
  }, [])

  useEffect (() => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(tasks))
  }, [tasks])

  function toggleTask(id) {
    const copyTasks = [...tasks]
    const task = copyTasks.find(task => task.id === id)
    task.complete = !task.complete
    setTasks(copyTasks)
  }

   
  function addTask(e){
    const name = taskRef.current.value
    const uuid = require('uuid')
    if (name === '') return
    setTasks(prevTask => {
      return [...prevTask, {id: uuid.v4(), name: name, complete:false}]
    })
    taskRef.current.value = null
  }

  function clearTask(){
    const copyTask = tasks.filter(task => !task.complete)
    setTasks(copyTask)
  }

  return (
    <div className="App">
      <h1>Checklist</h1>
      <h4>Your tasks</h4>

      <div>{tasks.filter(task => !task.complete).length} remaining tasks</div>
      <Checklist tasks={tasks} toggleTask={toggleTask}/>
      <input ref={taskRef} type='text' />
      <div>
        <button onClick={addTask}>Add</button>
        <button onClick={clearTask}>Clear completed tasks</button>
      </div>
    
    </div>
  );
}

export default App;
