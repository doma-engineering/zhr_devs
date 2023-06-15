function DragAndDrop() {
  return (
    <label
      className="flex justify-center w-full h-32 px-4 transition bg-slate-200 border-2 border-gray-300 border-dashed rounded-md appearance-none cursor-pointer hover:border-gray-400 focus:outline-none">
      <span className="flex items-center space-x-2">
        <span className="font-medium text-gray-600">
          Drop your solution here
        </span>
      </span>
      <input type="file" name="file_upload" className="hidden" />
    </label>
  )
}

export default DragAndDrop