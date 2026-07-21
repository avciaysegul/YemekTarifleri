import { act, fireEvent, render, screen } from "@testing-library/react";
import "@testing-library/jest-dom/vitest";
import { afterEach, describe, expect, it, vi } from "vitest";
import { kategoriMetni, Sayac, sureMetni, zorlukMetni } from "./App";

describe("Lua sayaç arayüzü", () => {
  afterEach(() => vi.useRealTimers());

  it("başlatılır, duraklatılır, sürdürülür ve Lua'ya completed döndürür", async () => {
    vi.useFakeTimers();
    const bitir = vi.fn(async () => undefined);
    render(<Sayac sure={3} dil="tr" bitir={bitir} />);

    fireEvent.click(screen.getByRole("button", { name: "Başlat" }));
    act(() => vi.advanceTimersByTime(1000));
    expect(screen.getByText("00:02")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Duraklat" }));
    act(() => vi.advanceTimersByTime(2000));
    expect(screen.getByText("00:02")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Devam et" }));
    await act(async () => vi.advanceTimersByTimeAsync(2000));
    expect(bitir).toHaveBeenCalledWith("completed");
  });

  it("kapatma sonucunu Lua'ya iletir", () => {
    const bitir = vi.fn(async () => undefined);
    render(<Sayac sure={30} dil="en" bitir={bitir} />);
    fireEvent.click(screen.getByRole("button", { name: "Close timer" }));
    expect(bitir).toHaveBeenCalledWith("closed");
  });
});

describe("katalog yerelleştirmesi", () => {
  it("kategori, süre ve zorluğu İngilizce gösterir", () => {
    expect(kategoriMetni("Ana Yemekler", "en")).toBe("Main dishes");
    expect(kategoriMetni("Tatlılar", "en")).toBe("Desserts");
    expect(sureMetni("20 dakika", "en")).toBe("20 min");
    expect(zorlukMetni("Kolay", "en")).toBe("Easy");
  });

  it("Türkçe metadata değerlerini değiştirmez", () => {
    expect(kategoriMetni("İçecekler", "tr")).toBe("İçecekler");
    expect(sureMetni("5 dakika", "tr")).toBe("5 dakika");
    expect(zorlukMetni("Orta", "tr")).toBe("Orta");
  });
});
