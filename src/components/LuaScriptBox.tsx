import { useEffect, useState } from "react";
import { Copy, Check, Trash2, RotateCcw } from "lucide-react";
import { toast } from "@/hooks/use-toast";

const SCRIPT_URL = "/scripts/painel-do-seven.lua";

const LuaScriptBox = () => {
  const [script, setScript] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  const loadScript = async () => {
    setLoading(true);
    try {
      const res = await fetch(SCRIPT_URL);
      if (!res.ok) throw new Error("fetch failed");
      setScript(await res.text());
    } catch {
      toast({ title: "Erro", description: "Não foi possível carregar o script.", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadScript();
  }, []);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(script);
      setCopied(true);
      toast({ title: "Copiado!", description: "Script Lua copiado para a área de transferência." });
      setTimeout(() => setCopied(false), 2000);
    } catch {
      toast({ title: "Erro", description: "Não foi possível copiar.", variant: "destructive" });
    }
  };

  const handleClear = () => setScript("");

  const lineCount = script.split("\n").length;
  const charCount = script.length;

  return (
    <div className="card-frost frost-glow flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <span className="stat-label">Painel_do_seven_1.0.8.lua</span>
        <span className="text-[10px] font-mono text-muted-foreground">
          {loading ? "carregando..." : `${lineCount} linhas · ${charCount} chars`}
        </span>
      </div>

      <textarea
        value={script}
        onChange={(e) => setScript(e.target.value)}
        spellCheck={false}
        placeholder="-- Cole seu script Lua aqui..."
        className="w-full min-h-[360px] font-mono text-sm bg-background/60 border border-border rounded-[12px] p-4 text-foreground resize-y focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/50 leading-relaxed"
      />

      <div className="flex gap-3">
        <button
          onClick={handleCopy}
          disabled={loading}
          className="btn-primary-full flex items-center justify-center gap-2"
        >
          {copied ? <Check className="w-5 h-5" /> : <Copy className="w-5 h-5" />}
          {copied ? "Copiado!" : "Copiar tudo"}
        </button>
        <button
          onClick={loadScript}
          className="px-5 rounded-[14px] border border-border bg-secondary text-secondary-foreground hover:bg-muted transition-colors flex items-center gap-2 font-semibold"
          aria-label="Restaurar script original"
        >
          <RotateCcw className="w-5 h-5" />
        </button>
        <button
          onClick={handleClear}
          className="px-5 rounded-[14px] border border-border bg-secondary text-secondary-foreground hover:bg-muted transition-colors flex items-center gap-2 font-semibold"
          aria-label="Limpar"
        >
          <Trash2 className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
};

export default LuaScriptBox;