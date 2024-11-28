export default function Home() {
  return (
    <div>
      <h1>`Hello World!! ${process.env.NEXT_PUBLIC_APP_SERVER_URL}`</h1>
    </div>
  );
}
