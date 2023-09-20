import React, { ChangeEvent, FC, useRef, useEffect } from "react";
import JSZip from "jszip";
import SHA256 from "crypto-js/sha256";
import WordArray from "crypto-js/lib-typedarrays";

const UploadComponent: FC<{ tech: string; taskId: string; task: string }> = ({
  tech,
  taskId,
  task
}) => {
  const generateHash = async (content: Blob): Promise<string> => {
    const buffer = await content.arrayBuffer();
    const uint8Array = new Uint8Array(buffer);
    const numberArray: number[] = Array.from(uint8Array);
    // Jumping through the hoops.
    const wordArray = WordArray.create(numberArray);
    return SHA256(wordArray).toString();
  };

  console.warn("STARTING UPLOAD COMPONENT");

  const handleChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const zip = new JSZip();

    const files = e.target.files;
    if (!files) return;

    const fileListArray = Array.from(files);
    // Handle each file
    for (let file of fileListArray) {
      // Add file to the ZIP with directory structure and set the modified date
      zip.file(file.webkitRelativePath || file.name, file, {
        date: new Date("1970-01-01"),
      });
    }

    const requestURL = `/my/task/nt/${task}/${tech}/${taskId}/submission`;

    // Generate the ZIP content
    const content = await zip.generateAsync({ type: "blob" });

    console.log("ZIP content:", content.size);

    // Get the hash of the ZIP content
    const hashName = await generateHash(content);

    console.log("ZIP Hash:", hashName);

    const formData = new FormData();
    formData.append("submission", content, `${hashName}.zip`);

    // Upload the ZIP file
    fetch(requestURL, { method: "POST", body: formData })
      .then((response) => console.log(response))
      .catch((error) => console.log(error));
  };

  const ref = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const customAttributes = [
      "webkitdirectory",
      "directory",
      "mozdirectory",
      "msdirectory",
      "odirectory",
    ];
    customAttributes.forEach((attr) => {
      if (ref.current) ref.current.setAttribute(attr, "");
    });
  }, [ref]);

  return (
    <div>
      <p>Choose a file:</p>
      <input type="file" onChange={handleChange} ref={ref} />
    </div>
  );
};

export default UploadComponent;
