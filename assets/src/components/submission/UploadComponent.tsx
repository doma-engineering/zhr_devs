import { ChangeEvent, FC, useRef, useEffect } from 'react';
import JSZip from 'jszip';

const UploadComponent: FC<{tech: string, taskId: string}> = ({tech, taskId}) => {
  const randomName = () => {
    const noisy = Math.random().toString(36).substring(2, 15);
    return noisy.replace(/[^a-z0-9]/gi, '_').toLowerCase();
  }

  const handleChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const zip = new JSZip();

    const files = e.target.files;
    if (!files) return;

    Array.from(files).forEach(f => {
      // @ts-ignore
      zip.file(f.name, f)
    });

    const requestURL = `/my/task/${tech}/${taskId}/submission`

    await zip.generateAsync({ type: "blob" }).then(content => {
      var formData = new FormData();
      formData.append("submission", content, randomName() + ".zip");
      fetch(requestURL, { method: "POST", body: formData });
    })
    .then(response => console.log(response))
    .catch(error => console.log(error))
  }

  const ref = useRef<HTMLInputElement>(null);
  const customAttributes = ['webkitdirectory', 'directory', 'mozdirectory', 'msdirectory', 'odirectory']

  useEffect(() => {
    customAttributes.forEach(attr => {
      if (ref.current) ref.current.setAttribute(attr, "");
    })
  }, [ref])

  return (
    <div>
      <input type="file" onChange={handleChange} ref={ref} />
    </div>
  );
}

export default UploadComponent;
