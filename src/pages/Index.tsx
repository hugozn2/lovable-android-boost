import LuaScriptBox from "../components/LuaScriptBox";

const Index = () => {
  return (
    <main className="min-h-screen bg-background text-foreground flex items-center justify-center p-4">
      <div className="w-full max-w-3xl">
        <header className="mb-6 text-center">
          <h1 className="text-3xl font-bold tracking-tight text-gradient-frost">
            Lua Script Vault
          </h1>
          <p className="text-sm text-muted-foreground mt-2">
            Cole seu script Lua e copie com um clique.
          </p>
        </header>
        <LuaScriptBox />
      </div>
    </main>
  );
};

export default Index;
