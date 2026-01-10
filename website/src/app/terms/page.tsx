import { readFileSync } from "fs";
import { join } from "path";
import { remark } from "remark";
import remarkGfm from "remark-gfm";
import remarkRehype from "remark-rehype";
import rehypeSlug from "rehype-slug";
import rehypeStringify from "rehype-stringify";

export default async function Terms() {
  const filePath = join(process.cwd(), "src", "lib", "terms.md");
  const fileContents = readFileSync(filePath, "utf8");
  const processedContent = await remark()
    .use(remarkGfm)
    .use(remarkRehype)
    .use(rehypeSlug)
    .use(rehypeStringify)
    .process(fileContents);
  const contentHtml = processedContent.toString();

  return (
    <div
      className="max-w-4xl mx-auto px-4 py-8 markdown-content"
      dangerouslySetInnerHTML={{ __html: contentHtml }}
    />
  );
}
